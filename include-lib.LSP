;;;=====================================================================
;;;    Please load this LISP file to your autolisp development
;;;  enviroment. Then the following function is declared.
;;;    Please see also include.LSP.
;;;
;;;    Use the following functions depending on your development
;;;  environment.
;;;
;;;          ----------------------+-------------------------
;;;            Visual LISP         |  Visual Studio CODE
;;;                                |  or Visual LISP
;;;          ----------------------+-------------------------
;;;            include             |  include
;;;                                |  load-file
;;;                                |  resource-file
;;;                                |  createPRV
;;;            exportResource      |
;;;            (or exportLib)      |
;;;          ----------------------+-------------------------
;;;
;;;=====================================================================
;;;  (include 'function filename)
;;;---------------------------------------------------------------------
;;;  function : symbol
;;;  filename : string
;;;---------------------------------------------------------------------
;;;    If no function is defined, the file will be loaded. The loaded
;;;  file name is stored in *include:LibraryFiles* .
;;;    This function is used to load a file from the library, if needed.
;;;=====================================================================
;;;  (load-file filename)
;;;---------------------------------------------------------------------
;;;  filename : string
;;;---------------------------------------------------------------------
;;;    The file is loaded and the name is stored in *include:LoadFiles* .
;;;    This function can be used to load your project's files from Visual
;;;  Studio Code instead of the load function in AutoCAD 2021 and later.
;;;  This is used in combination with the createPRV function.
;;;=====================================================================
;;;  (resource-file filename)
;;;---------------------------------------------------------------------
;;;  filename : string
;;;---------------------------------------------------------------------
;;;    The file name is stored in *include:ResourceFiles* .
;;;    This function remembers the name of the resource file so that it
;;;  can be used by the createPRV function. It has no direct effect on
;;;  the execution of your program. Specify a DCL or TXT file with this
;;;  function.
;;;=====================================================================
;;;  (createPRV obj-temp target-folder)
;;;---------------------------------------------------------------------
;;;  obj-temp      : string or nil (If nil, the default value is "temp")
;;;  target-folder : string or nil (If nil, the default value is "")
;;;---------------------------------------------------------------------
;;;    This function creates the VLX application make file (PRV) for
;;;  Visual LISP or command MAKELISPAPP. This configuration file contains
;;;  the contents of *include:LoadFiles*, *include:LibraryFiles* and
;;;  *include:ResourceFiles*.
;;;    The AutoCAD 2021 and later commands MAKELISPAPP enables the
;;;  creation of VLX applications without the use of VisualLISP projects.
;;;=====================================================================
;;;  (exportResource)
;;;---------------------------------------------------------------------
;;;    This function writes out a project file that can be used with
;;;  Visual LISP. The project file is the contents of *include:LibraryFiles*
;;;  loaded with the include function.
;;;    This project file can be included as a resource in the Visual LISP
;;;  VLX application definition file(PRV). In principle, this function
;;;  should be used if you are developing a program using Visual LISP
;;;  instead of Visual studio Code and MAKELISPAPP.
;;;=====================================================================
;;;  (exportLib fas-temp temp)
;;;---------------------------------------------------------------------
;;;  fas-temp : string or nil (If nil, the default value is "temp")
;;;  temp     : string or nil (If nil, the default value is "temp")
;;;---------------------------------------------------------------------
;;;    The basic behavior of this function is the same as the exportResource
;;;  function. You can change the content a little bit, depending on the
;;;  argument.
;;;    The fas-temp and temp arguments specify a temporary folder.
;;;    (exportLib nil nil) is the same as (exportResource).
;;;=====================================================================

;;; +------------------------------------------------------------------+
;;;   Copyright (c) 2020 manual chair japan                 
;;;   Released under the MIT license                        
;;;   https://opensource.org/licenses/mit-license.php       
;;; +------------------------------------------------------------------+

(setq *DrawingLevelEnviromet* T)

;;;*******************************************************************
;;;
;;; support functions
;;;
;;;*******************************************************************

(setq *include:LoadFiles*      nil
      *include:LibraryFiles*   nil
      *include:ResourceFiles*  nil
      *include:symbol-table*   nil
      *include:loading-stack*  nil ;;
       ;; *include:message-mode* = 0~   NOTICE, COUTION and ERROE
       ;;                          10~  COUTION and ERROE
       ;;                          100~ ERROR only
      *include:message-mode*   0
      *include:working-folder* nil
)

(defun include:message (level message) 
  (if (<= *include:message-mode* level) 
    (princ message)
  )
  nil
)

(defun include:replace-to-slash (path) 
  (if path 
    (vl-list->string 
      (mapcar 
        (function 
          (lambda (char) 
            (if (= char 92 ;|(ascii "\\")|;) 
              47
              ;|(ascii "/")|;
              char
            )
          )
        )
        (vl-string->list path)
      )
    )
  )
)

(defun include:normalize-path (path last-slash / last-char) 
  (if (/= path "") 
    (progn (setq last-char (vl-string-elt path (1- (strlen path)))) 
           (if (= last-char 47 ;|(ascii "/")|;) 
             (if last-slash 
               path
               (substr path 1 (1- (strlen path)))
             )
             (if last-slash 
               (strcat path "/")
               path
             )
           )
    )
    path
  )
)

(defun include:make-list (size initial-element) 
  (if (not (zerop size)) 
    (cons initial-element 
          (include:make-list (1- size) initial-element)
    )
  )
)

(defun include:trySearch:sub (extensions) 
  (if extensions 
    (if (setq full-filename (findfile (strcat filename "." (car extensions)))) 
      full-filename
      (include:trySearch:sub (cdr extensions))
    )
  )
)

(defun include:trySearch (filename extensions) 
  (include:trySearch:sub extensions)
)

(defun include:full-filename (filename extension-serach / full-filename path) 
  (include:replace-to-slash 
    (if (not (null (setq full-filename (findfile filename)))) 
      full-filename
      (if extension-serach 
        (include:trySearch 
          (if (/= (setq path (vl-filename-directory filename)) "") 
            (strcat path "/" (vl-filename-base filename))
            (vl-filename-base filename)
          )
          '("VLX" "FAS" "LSP")
        )
      )
    )
  )
)

(defun include:file-info (filename extension-serach load-file-symbol / file-info 
                          full-filename
                         ) 
  (if (setq full-filename (include:full-filename filename extension-serach)) 
    (cons (strcase filename) 
          (list (read (substr (vl-filename-extension full-filename) 2)) 
                full-filename
          )
    )
  )
)

(defun include:load-file ($_filename $_load-list-symbol / $_file-info $_list-item 
                          $_result
                         ) 
  (if 
    (setq $_file-info ;_ Check for file availability
                      (include:file-info $_filename T $_load-list-symbol)
    )
    (if 
      (vl-catch-all-error-p 
        (setq $_result (vl-catch-all-apply 
                         'load
                         (list (cadr (cdr $_file-info)))
                       )
        )
      )
      (progn 
        (include:message 
          100
          (strcat "\n; ERROR : An error occurred while loading " 
                  $_filename
                  " ."
          )
        )
        (exit)
      )
      (progn 
        (set $_load-list-symbol 
             (if 
               (setq $_list-item (assoc (strcase $_filename) 
                                        (vl-symbol-value $_load-list-symbol)
                                 )
               )
               (subst $_file-info 
                      $_list-item
                      (vl-symbol-value $_load-list-symbol)
               )
               (cons $_file-info (vl-symbol-value $_load-list-symbol))
             )
        )
        $_result
      )
    )
    (progn 
      (include:message 
        100
        (strcat "\n; ERROR : There is no module file - " 
                $_filename
                " ."
        )
      )
      (exit)
    )
  )
)

(defun include:check-circular-reference:dump-string (stack indent) 
  (if stack 
    (strcat "\n" 
            (include:make-list (* indent 2) 32 ;|(ascii " ")|;)
            "-->"
            (vl-princ-to-string (car stack))
            (include:check-circular-reference:dump-string 
              (cdr stack)
              (1+ indent)
            )
    )
    ""
  )
)

(defun include:check-circular-reference ($_func $_symbol-info $_load-list-symbol / 
                                         $_result
                                        ) 
  (if 
    (null 
      (vl-member-if 
        (function 
          (lambda (symbol-info) 
            (= (strcase (cdr symbol-info)) 
               (strcase (cdr $_symbol-info))
            )
          )
        )
        *include:loading-stack*
      )
    )
    (progn 
      (setq *include:loading-stack* (cons $_symbol-info 
                                          *include:loading-stack*
                                    )
      )
      (if 
        (vl-catch-all-error-p 
          (setq $_result (vl-catch-all-apply 
                           $_func
                           (list (cdr $_symbol-info) $_load-list-symbol)
                         )
          )
        )
        (progn (setq *include:loading-stack* nil) (exit))
        (progn 
          (setq *include:loading-stack* (cdr *include:loading-stack*))
          $_result
        )
      )
    )
    (include:message 
      0
      (strcat "\n; NOTICE : " 
              (cdr $_symbol-info)
              " of "
              (vl-symbol-name (car $_symbol-info))
              " is causing a circular reference!\n; STACK is -> "
              (include:check-circular-reference:dump-string 
                (recerce (cons $_symbol-info *include:loading-stack*))
                0
              )
      )
    )
  )
)


;;;*******************************************************************
;;;
;;; include function
;;;
;;;*******************************************************************

(defun include:symbol-info (asymbol filename / symbol-info) 
  (if (setq symbol-info (assoc asymbol *include:symbol-table*)) 
    (if (/= (strcase (cdr symbol-info)) (strcase filename)) 
      (progn 
        (include:message 
          10
          (strcat "\n; CAUTION : " 
                  (vl-symbol-name asymbol)
                  " is doubly defined in "
                  filename
                  " and "
                  (cdr symbol-info)
                  " ."
          )
        )
        (exit)
      )
    )
  )
  (cons asymbol filename)
)

(defun include ($_include:symbol $_include:filename / $_symbol-info $_list-item 
                $_result
               ) 
  (if 
    (and (not (boundp $_include:symbol)) 
         (setq $_symbol-info ;_ Check the double definition.
                             (include:symbol-info 
                               $_include:symbol
                               (include:replace-to-slash $_include:filename)
                             )
         )
    )
    (progn 
      (setq $_result               (include:check-circular-reference 
                                     'include:load-file
                                     $_symbol-info
                                     '*include:LibraryFiles*
                                   )
            *include:symbol-table* (if 
                                     (setq $_list-item (assoc $_include:symbol 
                                                              *include:symbol-table*
                                                       )
                                     )
                                     (subst $_symbol-info 
                                            $_list-item
                                            *include:symbol-table*
                                     )
                                     (cons $_symbol-info 
                                           *include:symbol-table*
                                     )
                                   )
      )
      (if (not (boundp $_include:symbol)) 
        (include:message 
          10
          (strcat "\n; CAUTION : " 
                  (vl-symbol-name $_include:symbol)
                  " is not defined in "
                  $_include:filename
          )
        )
      )
      $_result
    )
  )
)

;;;*******************************************************************
;;;
;;; load-file function
;;;
;;;*******************************************************************

(defun load-file ($_load-file:filename / $_result) 
  (include:check-circular-reference 
    'include:load-file
    (cons 
      (read 
        (strcat "$_load-file::" 
                (vl-filename-base $_load-file:filename)
        )
      )
      $_load-file:filename
    )
    '*include:LoadFiles*
  )
)

;;;*******************************************************************
;;;
;;; resource-file function
;;;
;;;*******************************************************************

(defun resource-file:main (filename / file-info list-item) 
  (if 
    (setq file-info ;_ Check for file availability
                    (include:file-info filename nil '*include:ResourceFiles*)
    )
    (setq *include:ResourceFiles* (if 
                                    (setq list-item (assoc (strcase filename) 
                                                           *include:ResourceFiles*
                                                    )
                                    )
                                    (subst file-info 
                                           list-item
                                           *include:ResourceFiles*
                                    )
                                    (cons file-info *include:ResourceFiles*)
                                  )
    )
    (progn 
      (princ 
        (strcat "\n; ERROR : There is no resource file - " 
                filename
                " ."
        )
      )
      (exit)
    )
  )
)

(defun resource-file (filename / ext) 
  (if (/= (setq ext (vl-filename-extension filename)) "") 
    (if (member (read (substr ext 2)) '(DCL PRJ TXT VLX FAS LSP)) 
      (resource-file:main filename)
      (progn (princ "\n; ERROR : Illegal file name extension. (DCL TXT)") 
             (exit)
      )
    )
    (progn 
      (princ 
        "\n; ERROR : The file name must have an extension. (DCL TXT)"
      )
      (exit)
    )
  )
)

;;;*******************************************************************
;;;
;;; createPRV function
;;;
;;;*******************************************************************

(defun createPRV:write:sub (file-info-list) 
  (if file-info-list 
    (progn 
      (princ 
        (strcat "\n    (:" 
                (strcase (vl-symbol-name (cadr (car file-info-list))) T)
                " "
                (vl-prin1-to-string (caddr (car file-info-list)))
                ")"
        )
        fp
      )
      (createPRV:write:sub (cdr file-info-list))
    )
  )
)

(defun createPRV:write (fp target obj-temp) 
  (princ ";;; Visual LISP Apprication make file" fp)
  (princ "\n(PRV-DEF" fp)
  (princ (strcat "\n  (:target . " (vl-prin1-to-string target) ")") 
         fp
  )
  (princ "\n  (:active-x . T)" fp)
  (princ "\n  (:separate-namespace . T)" fp)
  (princ "\n  (:protected . T)" fp)
  (princ "\n  (:load-file-list" fp)
  (createPRV:write:sub (reverse *include:LoadFiles*))
  ;;
  (princ "\n  )" fp)
  (princ "\n  (:require-file-list" fp)
  (createPRV:write:sub (reverse *include:LibraryFiles*))
  (createPRV:write:sub 
    (vl-sort *include:ResourceFiles* 
             (function 
               (lambda (file-info-1 file-info-2) 
                 (< (vl-position (cadr file-info-1) resource-order) 
                    (vl-position (cadr file-info-2) resource-order)
                 )
               )
             )
    )
  )
  ;;
  (princ "\n  )" fp)
  (princ 
    (strcat "\n  (:ob-directory . " 
            (vl-prin1-to-string obj-temp)
            ")"
    )
    fp
  )
  (princ "\n  (:tmp-directory)" fp)
  (princ "\n  (:optimization . st)" fp)
  (princ "\n)" fp)
  (princ "\n;;; EOF" fp)
)

(defun createPRV (obj-temp target-folder / resource-order filename fp) 
  (setq resource-order '(DCL PRJ TXT VLX FAS LSP))
  ;;
  (if 
    (setq filename (getfiled "Create Visual LISP PRV file" 
                             (if (null *include:working-folder*) 
                               (getvar "MYDOCUMENTSPREFIX")
                               *include:working-folder*
                             )
                             "prv"
                             (+ 1 4 16 128)
                   )
    )
    (if (setq fp (open filename "w")) 
      (progn 
        (if 
          (vl-catch-all-error-p 
            (vl-catch-all-apply 
              'createPRV:write
              (list fp 
                    (strcat 
                      (include:normalize-path 
                        (if (null target-folder) 
                          ""
                          (include:replace-to-slash target-folder)
                        )
                        T
                      )
                      (vl-filename-base filename)
                      ".VLX"
                    )
                    (if (null obj-temp) 
                      "temp"
                      (include:normalize-path 
                        (include:replace-to-slash obj-temp)
                        nil
                      )
                    )
              )
            )
          )
          (princ "\n; An error occurred while writing the file.")
          (progn (princ "\n; An application make file has been created.") 
                 (princ (strcat "\n; " (include:replace-to-slash filename)))
                 (if 
                   (not 
                     (or *include:LoadFiles* 
                         *include:LibraryFiles*
                         *include:ResourceFiles*
                     )
                   )
                   (princ "\n;\n; But the list of files was empty.\n;")
                 )
                 (setq *include:working-folder* (vl-filename-directory filename))
          )
        )
        (close fp)
      )
      (princ "\n; A file open error has occurred.")
    )
  )
  (princ)
)

;;;********************************************************************
;;; Below functions are used with only Visual LISP ********************
;;;********************************************************************

(if (or (null (getvar "LISPSYS")) (zerop (getvar "LISPSYS"))) 
  (progn 
    ;;*******************************************************************
    ;;
    ;; exportLib function
    ;;
    ;;*******************************************************************
    (defun exportLib:write:sub (file-info-list) 
      (if file-info-list 
        (progn 
          (princ 
            (strcat "\n    " 
                    (vl-prin1-to-string (caddr (car file-info-list)))
            )
            fp
          )
          (exportLib:write:sub (cdr file-info-list))
        )
      )
    )
    (defun exportLib:write (fp filename fas-temp temp single / fp) 
      (princ ";;; Visual LISP project file" fp)
      (princ "\n(VLISP-PROJECT-LIST" fp)
      (princ "\n  :NAME" fp)
      (princ (strcat "\n  " filename) fp)
      (princ "\n  :OWN-LIST" fp)
      (princ "\n  (" fp)
      (exportLib:write:sub (reverse *include:LibraryFiles*))
      (princ "\n  )" fp)
      (princ "\n  :FAS-DIRECTORY" fp)
      (princ (strcat "\n  " (vl-prin1-to-string fas-temp)) fp)
      (princ "\n  :TMP-DIRECTORY" fp)
      (princ (strcat "\n  " (vl-prin1-to-string temp)) fp)
      (princ "\n  :PROJECT-KEYS" fp)
      (princ 
        (strcat "\n  (:BUILD (:standard) :MERGED " 
                (if single 
                  "T"
                  "nil"
                )
                " :SAFE-MODE T :MSGLEVEL 1)"
        )
        fp
      )
      (princ "\n  :CONTEXT-ID" fp)
      (princ "\n  :AUTOLISP" fp)
      (princ "\n)" fp)
      (princ "\n;;; EOF" fp)
    )
    (defun exportLib (fas-temp temp / filename fp) 
      (if 
        (setq filename (getfiled "Export Libraries to Visual LISP Project file" 
                                 (if (null *include:working-folder*) 
                                   (getvar "MYDOCUMENTSPREFIX")
                                   *include:working-folder*
                                 )
                                 "prj"
                                 (+ 1 4 16 128)
                       )
        )
        (if (setq fp (open filename "w")) 
          (progn 
            (if 
              (vl-catch-all-error-p 
                (vl-catch-all-apply 
                  'exportLib:write
                  (list fp 
                        (vl-filename-base filename)
                        (if (null fas-temp) 
                          "temp"
                          (include:normalize-path 
                            (include:replace-to-slash fas-temp)
                            nil
                          )
                        )
                        (if (null temp) 
                          "temp"
                          (include:normalize-path 
                            (include:replace-to-slash temp)
                            nil
                          )
                        )
                        nil
                  )
                )
              )
              (princ "\n; An error occurred while writing the file.")
              (progn 
                (princ 
                  "\n; The list of library files was written to the project file"
                )
                (princ (strcat "\n; " (include:replace-to-slash filename)))
                (if (null *include:LibraryFiles*) 
                  (princ "\n;\n; But the list of files was empty.\n;")
                )
                (setq *include:working-folder* (vl-filename-directory filename))
              )
            )
            (close fp)
          )
          (princ "\n; A file open error has occurred.")
        )
      )
      (princ)
    )
    ;;*******************************************************************
    ;;
    ;; exportResource function
    ;;
    ;;*******************************************************************
    (defun exportResource () (exportLib nil nil))
  ) ;_ end-of-progn
) ;_ end-of-if

;;;

(princ "\ninclude-lib was loaded.")
(princ)