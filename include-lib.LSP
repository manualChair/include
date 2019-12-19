;;;=====================================================================
;;;  Please load this LISP file to your autolisp development enviroment.
;;;  Then the following function is declared.
;;;  please see also include.LSP.
;;;=====================================================================
;;;  (include 'function filename)
;;;---------------------------------------------------------------------
;;;  function : symbol
;;;  filename : string
;;;---------------------------------------------------------------------
;;;  If no function is defined, the file will be loaded.
;;;=====================================================================
;;;  (exportResource)
;;;---------------------------------------------------------------------
;;;  This function outputs a list of loaded functions as Project file.
;;;  You can use this Project file in resource part of VLX configuration 
;;;  file.
;;;=====================================================================

;;; +------------------------------------------------------------------+
;;;   Copyright (c) 2019 manual chair japan                 
;;;   Released under the MIT license                        
;;;   https://opensource.org/licenses/mit-license.php       
;;; +------------------------------------------------------------------+

(setq *include:ResourceFiles* nil
      *include:stack* nil
      *include:message-mode* 0
)

;;;

(defun include:message (level message)
  (if (<= *include:message-mode* level)
    (princ message)
  )
  nil
)

(defun include:trySearch (extensions / full-filename)
  (if extensions
    (if (setq full-filename
               (findfile
                 (strcat $_include:resource "." (car extensions))
               )
        )
      (cons (read (car extensions)) full-filename)
      (include:trySearch (cdr extensions))
    )
    nil
  )
)

(defun include:findfile (/ temp)
  (if (setq
        temp (if (setq $_ext (vl-filename-extension $_include:resource))
               (cons (read (substr $_ext 2)) (findfile $_include:resource))
               (include:trySearch '("VLX" "FAS" "LSP"))
             )
      )
    temp
    (progn (include:message
             100
             (strcat "\n; ERROR : There is no module file - \""
                     $_include:resource
                     "\""
             )
           )
           (setq *include:stack* nil)
           (exit)
    )
  )
)

(defun include:alreadyloaded ()
  (if (/= (car $_temp) $_include:symbol)
    (include:message
      0
      (strcat "\n; NOTICE : "
              $_include:resource
              " is loaded by "
              (vl-symbol-name (car (car $_temp)))
              " & "
              (vl-symbol-name $_include:symbol)
      )
    )
  )
  nil
)

(defun include:main ()
  (load (cdr $_include:file-info))
  (if (not (boundp $_include:symbol))
    (include:message
      10
      (strcat "\n; CAUTION : "
              (vl-symbol-name $_include:symbol)
              " is not defined in "
              $_include:resource
      )
    )
    (setq *include:ResourceFiles*
           (cons
             (cons $_include:symbol $_include:file-info)
             *include:ResourceFiles*
           )
    )
  )
)

(defun include ($_include:symbol    $_include:resource
                /                   $_include:file-info
                $_ext               $_temp
               )
  (if (and (setq $_include:file-info (include:findfile))
           (not (boundp $_include:symbol))
      )
    (if (setq
          $_temp (vl-member-if
                   (function
                     (lambda (include:filename)
                       (equal (cdr include:filename) $_include:file-info)
                     )
                   )
                   *include:ResourceFiles*
                 )
        )
      (include:alreadyloaded)
      (if (member (strcase $_include:resource) *include:stack*)
        (include:message
          0
          (strcat "\n; NOTICE : "
                  $_include:resource
                  " of "
                  (vl-symbol-name $_include:symbol)
                  " is causing a circular reference!\n; STACK is -> "
                  (vl-princ-to-string
                    (cons (strcase $_include:resource) *include:stack*)
                  )
          )
        )
        (progn (setq *include:stack*
                      (cons (strcase $_include:resource)
                            *include:stack*
                      )
               )
               (include:main)
               (setq *include:stack* (cdr *include:stack*))
               $_include:symbol
        )
      )
    )
  )
)

;;;

(defun exportResourceToProject:sub (rlist)
  (if rlist
    (progn (princ (strcat "\n    " (vl-prin1-to-string (car rlist))) fp)
           (exportResourceToProject:sub (cdr rlist))
    )
  )
)

(defun exportResourceToProject (filename / fp)
  (if (setq fp (open filename "w"))
    (progn
      (princ "(VLISP-PROJECT-LIST" fp)
      (princ "\n  :NAME" fp)
      (princ "\n  " fp)
      (princ (vl-filename-base filename) fp)
      (princ "\n  :OWN-LIST" fp)
      (princ "\n  (" fp)
      (exportResourceToProject:sub
        (acad_strlsort (mapcar 'cddr *include:ResourceFiles*))
      )
      (princ "\n  )" fp)
      (princ "\n  :FAS-DIRECTORY" fp)
      (princ "\n  \"./temp\"" fp)
      (princ "\n  :TMP-DIRECTORY" fp)
      (princ "\n  \"./temp\"" fp)
      (princ "\n  :PROJECT-KEYS" fp)
      (princ "\n  (:BUILD (:standard) :MERGED nil :SAFE-MODE T :MSGLEVEL 1)"
             fp
      )
      (princ "\n  :CONTEXT-ID" fp)
      (princ "\n  :AUTOLISP" fp)
      (princ "\n)" fp)
      (princ "\n" fp)
      (close fp)
    )
  )
)

(defun exportResource ()
  (if (setq filename (getfiled "Export resources to Project file"
                               (getvar "MYDOCUMENTSPREFIX")
                               "prj"
                               (+ 1 4 16 128)
                     )
      )
    (progn (exportResourceToProject filename)
           (princ "\n; Resouce files was exported as project file.")
           (princ (strcat "\n; " filename))
    )
  )
  (princ)
)

;;;

(setq *DrawingLevelEnviromet* T)

