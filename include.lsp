;;;=====================================================================
;;;    Please register this file at the top of youe project files in
;;;  Visual LISP, when you make Separate-namespace VLX Application.
;;;    If you are using Visual Studio Code with AutoCAD 2021 or later,
;;;  make sure it loads before your project's files.
;;;    The functions described in this file are a companion to the
;;;  functions described in include-lib.LSP and will only work if loaded
;;;  in Separate-namespace.
;;;    Please see also include-lib.LSP
;;;=====================================================================
;;;  (include 'function filename)
;;;---------------------------------------------------------------------
;;;  function : symbol
;;;  filename : string
;;;---------------------------------------------------------------------
;;;    If no function is defined, the file will be loaded in Separate-
;;;  namespace VLX Application.
;;;=====================================================================
;;;  NOTE
;;;    In its Separate-namespace, the load-file and resource-file
;;;  functions will have no effect.
;;;=====================================================================

;;; +------------------------------------------------------------------+
;;;   Copyright (c) 2020 manual chair japan                 
;;;   Released under the MIT license                        
;;;   https://opensource.org/licenses/mit-license.php       
;;; +------------------------------------------------------------------+

(if (null *DrawingLevelEnviromet*) 
  (setq *include:stack* nil
        include         (lambda ($_include:symbol $_include:resource / 
                                 $_filename-base
                                ) 
                          (if 
                            (and (not (boundp $_include:symbol)) 
                                 (null 
                                   (member 
                                     (setq $_filename-base (vl-filename-base 
                                                             $_include:resource
                                                           )
                                     )
                                     *include:stack*
                                   )
                                 )
                            )
                            (progn 
                              (setq *include:stack* (cons $_filename-base 
                                                          *include:stack*
                                                    )
                              )
                              (load $_filename-base 
                                    '(princ
                                      (strcat 
                                        "\n; Resource Load Error : "
                                        $_filename-base
                                      )
                                     )
                              )
                              (setq *include:stack* (cdr *include:stack*))
                              $_include:symbol
                            )
                          )
                        )
        load-file       (lambda (filename) nil)
        resource-file   (lambda (filename) nil)
  )
)