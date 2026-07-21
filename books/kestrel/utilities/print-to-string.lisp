; Printing an item to a string
;
; Copyright (C) 2023 Kestrel Institute
;
; License: A 3-clause BSD license. See the file books/3BSD-mod.txt.
;
; Author: Eric Smith (eric.smith@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This book puts fms-to-string and the related utilities into guard-verified
; :logic mode. The guards being verified are declared in the ACL2 sources
; (basis-a.lisp, basis-b.lisp, other-events.lisp).

(in-package "ACL2")

(local (include-book "system/fmt-support" :dir :system))


(local (in-theory (disable eviscerate-top-state-p
                           standard-evisc-tuplep fmt-state-p error1-state-p open-output-channel-p1
                           fmt1!
                           fmt1
                           fmt0
                           fmt-abbrev1
                           error1
                           error-fms
                           add-pair
                           error-fms-channel
                           princ$
                           )))

; -------------------
; Supporting functions.

(verify-termination set-ppr-flat-right-margin)

(verify-termination chk-current-package)

(local
 (defthm car-of-error1
   (equal (car (error1 ctx summary str alist state)) t)
   :hints (("Goal" :in-theory (enable error1)))))

(verify-termination set-current-package)

(verify-termination set-current-package-state)

(verify-termination set-iprint-ar)

(verify-termination block-iprint-ar
  (declare (xargs :guard-hints (("Goal" :in-theory (disable boundp-global
                                                            get-global))))))

(verify-termination override-global-evisc-table)

(verify-termination fmt-control-alistp)

; -------------------
; The -to-string wrappers.

(verify-termination fms-to-string-fn)

(verify-termination fms!-to-string-fn)

(verify-termination fmt-to-string-fn)

(verify-termination fmt!-to-string-fn)

(verify-termination fmt1-to-string-fn)

(verify-termination fmt1!-to-string-fn)

; -------------------
; Print an item to a string.

;; todo: make this lowercase?
;; todo: verify guards
(defun print-to-string (item)
  (mv-let (col string)
    (fmt1-to-string "~X01" (acons #\0 item (acons #\1 nil nil)) 0
                    :fmt-control-alist
                    `((fmt-soft-right-margin . 10000)
                      (fmt-hard-right-margin . 10000)))
    (declare (ignore col))
    string))
