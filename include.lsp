;;;=====================================================================
;;;  Please register this file at the top of youe project files,
;;;  when you make Separate-namespace VLX Application.
;;;  Please see also include-lib.LSP
;;;=====================================================================
;;;  (include 'function filename)
;;;---------------------------------------------------------------------
;;;  function : symbol
;;;  filename : string
;;;---------------------------------------------------------------------
;;;  If no function is defined, the file will be loaded in Separate-
;;;  namespace VLX Application.
;;;=====================================================================

;;; +------------------------------------------------------------------+
;;;   Copyright (c) 2019 manual chair japan                 
;;;   Released under the MIT license                        
;;;   https://opensource.org/licenses/mit-license.php       
;;; +------------------------------------------------------------------+

(if (null *DrawingLevelEnviromet*)
  (progn
    (setq *include:stack* nil)
    (defun include ($_include:symbol $_include:resource / $_filename-base)
      (if
        (and
          (not (boundp $_include:symbol))
          (null
            (member
              (setq $_filename-base (vl-filename-base $_include:resource))
              *include:stack*
            )
          )
        )
         (progn
           (setq *include:stack* (cons $_filename-base *include:stack*))
           (load $_filename-base)
           (setq *include:stack* (cdr *include:stack*))
           $_include:symbol
         )
      )
    )
  )
)
