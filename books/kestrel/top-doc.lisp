; Extract and export only Kestrel xdoc material
;
; Copyright (C) 2021-2023 Kestrel Institute
;
; License: A 3-clause BSD license. See the file books/3BSD-mod.txt.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)
; Author: Eric Smith (eric.smith@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

;; This book exports all the xdoc topics for the kestrel books (topics that
;; come in via the local include-books below and that were introduced in the
;; books/kestrel/ subtree).  It does not export definitions, theorems, etc.

(include-book "kestrel/utilities/xdoc-archiving" :dir :system)

(local
 (progn
   (include-book "acl2pl/top")
   (include-book "apt/doc")
   (include-book "axe/doc")
   (include-book "arithmetic-light/doc")
   (include-book "built-ins/top")
   (include-book "bv/doc")
   (include-book "bv-lists/doc")
   (include-book "auto-termination/top") ; omits some books (see file for why)
   (include-book "bibtex/xdoc-generation")
   (include-book "bitcoin/top")
   (include-book "c/top")
   (merge-io-pairs
    dm::primep
    (include-book "crypto/top"))
   (include-book "error-checking/top")
   (include-book "event-macros/top")
   (include-book "hdwallet/top")
   (include-book "ethereum/top")
   (include-book "file-io-light/doc")
   (include-book "fty/top")
   (include-book "helpers/doc")
   (include-book "htclient/top")
   (include-book "isar/top")
   (include-book "java/top")
   (include-book "jvm/doc")
   (include-book "json/top")
   (include-book "lists-light/doc")
   (include-book "number-theory/top")
   (include-book "prime-fields/doc")
   (include-book "risc-v/top")
   (include-book "simpl-imp/top")
   (include-book "soft/top")
   (include-book "solidity/top")
   (include-book "strings-light/doc")
   (include-book "syntheto/top")
   (include-book "treeset/top")
   (include-book "typed-lists-light/doc")
   (include-book "utilities/top")
   (include-book "utilities/doc")
   (include-book "utilities/io/doc")
   (include-book "utilities/show-books-doc")
   (include-book "utilities/ubi-doc")
   (include-book "utilities/checkpoints-doc")
   (include-book "yul/top")
   (include-book "zcash/top")

; (depends-on "images/kestrel-logo.png")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   (defxdoc kestrel-books

     :parents (software-verification)

     :short "A collection of ACL2 books contributed mainly by Kestrel Institute."

     :long

     (xdoc::topstring

      (xdoc::img :src "res/kestrel-images/kestrel-logo.png")

      (xdoc::p
       "The <b>Kestrel Books</b> are a collection of ACL2 books
        contributed mainly by "
       (xdoc::a :href "http://www.kestrel.edu" "Kestrel Institute")
       ". The Kestrel Books are freely available under a liberal license.
        Specific copyright, author, and license information
        is provided in the individual files and subdirectories.")

      (xdoc::p
       "As they become more stable,
        parts of the Kestrel Books may be moved
        to other locations in the "
       (xdoc::seetopic "community-books" "Community Books")
       ". For example, "
       (xdoc::seetopic "std" "STD")
       " and "
       (xdoc::seetopic "x86isa" "X86ISA")
       " include some Kestrel contributions.")

      (xdoc::p
       "Many of the Kestrel Books build upon,
        and are meant to extend and be compatible with,
        the ACL2 system code
        and various existing libraries such as "
       (xdoc::seetopic "std" "STD") ", "
       (xdoc::seetopic "fty" "FTY") ", "
       (xdoc::seetopic "seq" "Seq") ", and others.")))

   (xdoc::add-resource-directory "kestrel-images" "images")

   (xdoc::add-resource-directory "kestrel-design-notes" "design-notes")
   ))

;; Export xdoc material from the books locally included above:
(xdoc::archive-topics-for-books-tree "kestrel")
(xdoc::archive-current-resource-dirs)
