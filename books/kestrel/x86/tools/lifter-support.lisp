; Supporting tools for x86 lifters
;
; Copyright (C) 2016-2019 Kestrel Technology, LLC
; Copyright (C) 2020-2025 Kestrel Institute
;
; License: A 3-clause BSD license. See the file books/3BSD-mod.txt.
;
; Author: Eric Smith (eric.smith@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "X")

(include-book "kestrel/utilities/make-cons-nest" :dir :system)
(include-book "kestrel/alists-light/lookup-equal" :dir :system)
(include-book "kestrel/bv-lists/bv-array-conversions" :dir :system)
(include-book "kestrel/bv/bvchop-def" :dir :system) ; mentioned below
(include-book "kestrel/utilities/translate" :dir :system)
(include-book "../read-and-write")

;; An "output-indicator" indicates the desired result of lifting, either :all
;; or some component of the state.  There is no recognizer for an
;; output-indicator, such as 'output-indicatorp'.  Instead we call
;; wrap-in-normal-output-extractor on whatever the user supplies and we check
;; for an error.

(mutual-recursion
  ;; Create a term representing the extraction of the indicated output from TERM.
  ;; why "normal"?  maybe "component" ?  or non-trivial?
  ;; This can translate some parts of the output-indicator.
  (defun wrap-in-normal-output-extractor (output-indicator term wrld)
    (declare (xargs :guard (plist-worldp wrld)
                    :mode :program ; because of translate-term
                    ))
    (if (symbolp output-indicator)
        (case output-indicator
          ;; Extract a 64-bit register (we convert to an unsigned value):
          (:rax `(bvchop '64 (rax ,term)))
          (:rbx `(bvchop '64 (rbx ,term)))
          (:rcx `(bvchop '64 (rcx ,term)))
          (:rdx `(bvchop '64 (rdx ,term)))
          (:rsi `(bvchop '64 (rsi ,term)))
          (:rdi `(bvchop '64 (rdi ,term)))
          (:r8 `(bvchop '64 (r8 ,term)))
          (:r9 `(bvchop '64 (r9 ,term)))
          (:r10 `(bvchop '64 (r10 ,term)))
          (:r11 `(bvchop '64 (r11 ,term)))
          (:r12 `(bvchop '64 (r12 ,term)))
          (:r13 `(bvchop '64 (r13 ,term)))
          (:r14 `(bvchop '64 (r14 ,term)))
          (:r15 `(bvchop '64 (r15 ,term)))
          (:rsp `(bvchop '64 (rsp ,term)))
          (:rbp `(bvchop '64 (rbp ,term)))

          ;; todo: call eax or use choped rax here?
          (:eax `(bvchop '32 (xr ':rgf '0 ,term))) ; for now, or do something different depending on 32/64 bit mode since eax is not really well supported in 32-bit mode?
          ;; (:eax (rax ,term))
          (:xmm0 `(bvchop '128 (xr ':zmm '0 ,term)))
          (:ymm0 `(bvchop '256 (xr ':zmm '0 ,term)))
          (:zmm0 `(xr ':zmm '0 ,term)) ; seems to already be unsigned
          ;; Extract a CPU flag: ; todo: more?
          (:af `(get-flag ':af ,term)) ; todo: more
          (:cf `(get-flag ':cf ,term))
          (:of `(get-flag ':of ,term))
          (:pf `(get-flag ':pf ,term))
          (:sf `(get-flag ':sf ,term))
          (:zf `(get-flag ':zf ,term))
          (t (er hard? 'wrap-in-normal-output-extractor "Unsupported output-indicator: ~x0." output-indicator)))
      (if (not (and (consp output-indicator)
                    (true-listp output-indicator)))
          (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)
        (case (ffn-symb output-indicator)
          ;; (:register <N>)
          (:register (if (and (eql 1 (len (fargs output-indicator)))
                              (natp (farg1 output-indicator)) ;todo: what is the max allowed?
                              )
                         `(xr ':rgf ',(farg1 output-indicator) ,term)
                       (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          ;;  (:register-bool <N>)
          ;; TODO: Deprecate this case but the tester uses :register-bool
          ;; On Linux with gcc, a C function that returns a boolean has been observed to only set the low byte of RAX
          ;; TODO: Should we chop to a single bit?
          (:register-bool (if (and (eql 1 (len (fargs output-indicator)))
                                   (natp (farg1 output-indicator)) ;todo: what is the max allowed?
                                   )
                              `(bvchop '8 (xr ':rgf ',(farg1 output-indicator) ,term))
                            (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          ;; (:mem32 <ADDR-TERM>)
          ;; TODO: Add other sizes of :memXXX
          (:mem32 (if (eql 1 (len (fargs output-indicator)))
                      `(read '4 ,(translate-term (farg1 output-indicator) 'wrap-in-normal-output-extractor wrld) ,term)
                    (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          ;; (:byte-array <ADDR-TERM> <LEN>) ; not sure what order is best for the args
          (:byte-array (if (and (eql 2 (len (fargs output-indicator)))
                                (posp (farg2 output-indicator)) ; number of bytes to read
                                )
                           `(acl2::list-to-byte-array (read-bytes ,(translate-term (farg1 output-indicator) 'wrap-in-normal-output-extractor wrld)
                                                                  ',(farg2 output-indicator)
                                                                  ,term))
                         (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          ;; (:array <bits-per-element> <element-count> <addr-term>) ; not sure what order is best for the args
          (:array (if (and (eql 3 (len (fargs output-indicator)))
                           (posp (farg1 output-indicator))
                           (= 0 (mod (farg1 output-indicator) 8)) ; bits-per-element must be a multiple of 8
                           (natp (farg2 output-indicator)) ; or use posp?
                           )
                      `(acl2::list-to-bv-array ',(farg1 output-indicator)
                                               (read-chunks ,(translate-term (farg3 output-indicator) 'wrap-in-normal-output-extractor wrld)
                                                            ',(farg2 output-indicator)
                                                            ',(/ (farg1 output-indicator) 8)
                                                           ,term))
                    (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          (:bv-list ;; (:bv-list <bits-per-element> <element-count> <addr-term>)
           (if (and (= 3 (len (fargs output-indicator)))
                    (posp (farg1 output-indicator))
                    (= 0 (mod (farg1 output-indicator) 8)) ; bits-per-element must be a multiple of 8
                    (natp (farg2 output-indicator)) ; or use posp?
                    )
               `(read-chunks ,(translate-term (farg3 output-indicator) 'wrap-in-normal-output-extractor wrld)
                             ',(farg2 output-indicator)
                             ',(/ (farg1 output-indicator) 8)
                             ,term)
             (er hard? 'wrap-in-normal-output-extractor "Bad output-indicator: ~x0." output-indicator)))
          ;; (:tuple ... output-indicators ...)
          ;; todo: what if no args?
          (:tuple (acl2::make-cons-nest (wrap-in-normal-output-extractors (fargs output-indicator) term wrld)))
          (otherwise (er hard? 'wrap-in-output-extractor "Bad output indicator: ~x0" output-indicator))))))

  (defun wrap-in-normal-output-extractors (output-indicators term wrld)
    (declare (xargs :guard (and (true-listp output-indicators)
                                (plist-worldp wrld))
                    :mode :program ; because of translate-term
                    ))
    (if (endp output-indicators)
        nil
      (cons (wrap-in-normal-output-extractor (first output-indicators) term wrld)
            (wrap-in-normal-output-extractors (rest output-indicators) term wrld)))))

;; Wraps TERM as indicated by OUTPUT-INDICATOR.
;; todo: reorder args?
(defun wrap-in-output-extractor (output-indicator term wrld)
  (declare (xargs :guard (plist-worldp wrld)
                  :mode :program ; because of translate-term
                  ))
  (if (eq :all output-indicator)
      term
    (wrap-in-normal-output-extractor output-indicator term wrld)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-x86-lifter-table (state)
  (declare (xargs :stobjs state))
  (table-alist 'x86-lifter-table (w state)))

;TODO: Use the generic utility for redundancy checking
;WHOLE-FORM is a call to the lifter
(defun previous-lifter-result (whole-form state)
  (declare (xargs :stobjs state))
  (let* ((table-alist (get-x86-lifter-table state)))
    (if (not (alistp table-alist))
        (hard-error 'previous-lifter-result "Invalid table alist for x86-lifter-table: ~x0."
                    (acons #\0 table-alist nil))
      (let ((previous-result (acl2::lookup-equal whole-form table-alist)))
        (if previous-result
            (prog2$ (cw "NOTE: The call to the lifter ~x0 is redundant.~%" whole-form)
                    previous-result)
          nil)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst *executable-types32* '(:pe-32 :mach-o-32 :elf-32))
(defconst *executable-types64* '(:pe-64 :mach-o-64 :elf-64))
(defconst *executable-types* (append *executable-types32* *executable-types64*))

;; The type of an x86 executable
(defun executable-typep (type)
  (declare (xargs :guard t))
  (member-eq type *executable-types*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Returns a symbol-list.
(defund maybe-add-debug-rules (debug-rules monitor)
  (declare (xargs :guard (and (or (eq :debug monitor)
                                  (symbol-listp monitor))
                              (symbol-listp debug-rules))))
  (if (eq :debug monitor)
      debug-rules
    (if (member-eq :debug monitor)
        ;; replace :debug in the list with all the debug-rules:
        (union-eq debug-rules (remove-eq :debug monitor))
      ;; no special treatment:
      monitor)))
