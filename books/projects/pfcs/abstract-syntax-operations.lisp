; PFCS (Prime Field Constraint System) Library
;
; Copyright (C) 2025 Kestrel Institute (https://www.kestrel.edu)
; Copyright (C) 2025 Provable Inc. (https://www.provable.com)
;
; License: See the LICENSE file distributed with this library.
;
; Author: Alessandro Coglio (www.alessandrocoglio.info)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "PFCS")

(include-book "abstract-syntax-trees")

(include-book "std/util/deflist" :dir :system)

(local (include-book "std/lists/intersectp" :dir :system))
(local (include-book "std/lists/no-duplicatesp" :dir :system))
(local (include-book "std/typed-lists/string-listp" :dir :system))

(local (include-book "kestrel/built-ins/disable" :dir :system))
(local (acl2::disable-most-builtin-logic-defuns))
(local (acl2::disable-builtin-rewrite-rules-for-defaults))
(set-induction-depth-limit 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc+ abstract-syntax-operations
  :parents (abstract-syntax)
  :short "Operations on the abstract syntax of PFCSes."
  :order-subtopics t
  :default-parent t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(std::defprojection name-simple-list (x)
  :guard (string-listp x)
  :returns (names name-listp)
  :short "Lift @(tsee name-simple) to lists."
  (name-simple x)

  ///

  (fty::deffixequiv name-simple-list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define names-indexed-below ((base stringp) (n natp))
  :returns (names name-listp)
  :short "Create a list of indexed names,
          with the same base and indices from 0 to @('n-1')
          (i.e. below @('n'))."
  (rev (names-indexed-below-rev base n))

  :prepwork
  ((define names-indexed-below-rev ((base stringp) (n natp))
     :returns (names-rev name-listp)
     :parents nil
     (b* (((when (zp n)) nil)
          (n-1 (1- n))
          (name (name-indexed base n-1))
          (names (names-indexed-below-rev base n-1)))
       (cons name names))

     ///

     (defret len-of-names-indexed-below-rev
       (equal (len names-rev)
              (nfix n))
       :hints (("Goal"
                :induct t
                :in-theory (enable names-indexed-below-rev nfix fix len))))

     (defret consp-of-names-indexed-below-rev
       (equal (consp names-rev)
              (> (nfix n) 0))
       :hints (("Goal" :induct t :in-theory (enable nfix))))

     (defret names-indexed-below-rev-iff
       (iff names-rev
            (> (nfix n) 0))
       :hints (("Goal" :induct t :in-theory (enable nfix))))

     (defruled base-not-member-of-names-indexed-below-rev
       (implies (stringp base)
                (not (member-equal (name-simple base)
                                   (names-indexed-below-rev base n))))
       :induct t
       :enable names-indexed-below-rev)

     (defruled member-equal-of-name-indexed-and-names-indexed-below-rev
       (iff (member-equal (name-indexed base i)
                          (names-indexed-below-rev base1 n))
            (and (equal (str-fix base)
                        (str-fix base1))
                 (< (nfix i) (nfix n))))
       :induct t
       :enable nfix)

     (defruled member-equal-of-names-indexed-below-rev
       (iff (member-equal x (names-indexed-below-rev base n))
            (and (namep x)
                 (equal (name-kind x) :indexed)
                 (equal (name-indexed->base x) (str-fix base))
                 (< (name-indexed->index x) (nfix n))))
       :induct t
       :enable nfix)

     (defrule no-duplicatesp-equal-of-names-indexed-below-rev
       (no-duplicatesp-equal (names-indexed-below-rev base n))
       :induct t
       :enable (no-duplicatesp-equal
                member-equal-of-name-indexed-and-names-indexed-below-rev))

     (defruled intersectp-equal-of-names-indexed-below-rev
       (equal (intersectp-equal (names-indexed-below-rev base1 n1)
                                (names-indexed-below-rev base2 n2))
              (and (equal (str-fix base1)
                          (str-fix base2))
                   (not (zp n1))
                   (not (zp n2))))
       :induct t
       :enable (member-equal-of-names-indexed-below-rev nfix zp))))

  ///

  (defret len-of-names-indexed-below
    (equal (len names)
           (nfix n)))

  (defret consp-of-names-indexed-below
    (equal (consp names)
           (> (nfix n) 0)))

  (defret names-indexed-below-iff
    (iff names
         (> (nfix n) 0)))

  (in-theory (disable consp-of-names-indexed-below
                      consp-of-names-indexed-below-rev))

  (defruled base-not-member-of-names-indexed-below
    (implies (stringp base)
             (not (member-equal (name-simple base) (names-indexed-below base n))))
    :use base-not-member-of-names-indexed-below-rev
    :enable names-indexed-below)

  (defruled member-equal-of-names-indexed-below
    (iff (member-equal x (names-indexed-below base n))
         (and (namep x)
              (equal (name-kind x) :indexed)
              (equal (name-indexed->base x) (str-fix base))
              (< (name-indexed->index x) (nfix n))))
    :enable member-equal-of-names-indexed-below-rev)

  (defruled member-equal-of-name-indexed-and-names-indexed-below
    (iff (member-equal (name-indexed base i)
                       (names-indexed-below base1 n))
         (and (equal (str-fix base)
                     (str-fix base1))
              (< (nfix i) (nfix n))))
    :enable member-equal-of-name-indexed-and-names-indexed-below-rev)

  (defrule no-duplicatesp-equal-of-names-indexed-below
    (no-duplicatesp-equal (names-indexed-below base n)))

  (defruled intersectp-equal-of-names-indexed-below
    (equal (intersectp-equal (names-indexed-below base1 n1)
                             (names-indexed-below base2 n2))
           (and (equal (str-fix base1)
                       (str-fix base2))
                (not (zp n1))
                (not (zp n2))))
    :enable intersectp-equal-of-names-indexed-below-rev))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(std::defprojection expression-var-list (x)
  :guard (name-listp x)
  :returns (exprs expression-listp)
  :short "Lift @(tsee expression-var) to lists."
  (expression-var x)

  ///

  (fty::deffixequiv expression-var-list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(std::deflist expression-var-listp (x)
  :guard (expression-listp x)
  :short "Check if all the expressions in a list are variables."
  (expression-case x :var)
  :elementp-of-nil nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(std::deflist expression-const/var-listp (x)
  :guard (expression-listp x)
  :short "Check if all the expressions in a list are constants or variables."
  (or (expression-case x :const)
      (expression-case x :var))
  :elementp-of-nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define expression-vars ((expr expressionp))
  :returns (vars name-setp)
  :short "Set of variables in an expression."
  (expression-case
   expr
   :const nil
   :var (set::insert expr.name nil)
   :neg (expression-vars expr.arg)
   :add (set::union (expression-vars expr.arg1)
                    (expression-vars expr.arg2))
   :sub (set::union (expression-vars expr.arg1)
                    (expression-vars expr.arg2))
   :mul (set::union (expression-vars expr.arg1)
                    (expression-vars expr.arg2)))
  :measure (expression-count expr)
  :hints (("Goal" :in-theory (enable o< o-finp)))
  :verify-guards :after-returns)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define expression-list-vars ((exprs expression-listp))
  :returns (vars name-setp)
  :short "Set of variables in a list of expressions."
  (cond ((endp exprs) nil)
        (t (set::union (expression-vars (car exprs))
                       (expression-list-vars (cdr exprs)))))
  :verify-guards :after-returns

  ///

  (defrule expression-list-vars-of-expression-var-list
    (equal (expression-list-vars (expression-var-list vars))
           (set::mergesort (name-list-fix vars)))
    :induct t
    :enable (expression-vars
             expression-var-list
             set::mergesort))

  (defrule expression-list-vars-of-cons
    (equal (expression-list-vars (cons expr exprs))
           (set::union (expression-vars expr)
                       (expression-list-vars exprs))))

  (defrule expression-list-vars-of-append
    (equal (expression-list-vars (append exprs1 exprs2))
           (set::union (expression-list-vars exprs1)
                       (expression-list-vars exprs2)))
    :induct t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-vars ((constr constraintp))
  :returns (vars name-setp)
  :short "Set of variables in a constraint."
  (constraint-case
   constr
   :equal (set::union (expression-vars constr.left)
                      (expression-vars constr.right))
   :relation (expression-list-vars constr.args)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-list-vars ((constrs constraint-listp))
  :returns (vars name-setp)
  :short "Set of variables in a list of constraints."
  (cond ((endp constrs) nil)
        (t (set::union (constraint-vars (car constrs))
                       (constraint-list-vars (cdr constrs)))))
  :verify-guards :after-returns

  ///

  (defrule constraint-list-vars-of-cons
    (equal (constraint-list-vars (cons constr constrs))
           (set::union (constraint-vars constr)
                       (constraint-list-vars constrs))))

  (defrule constraint-list-vars-of-append
    (equal (constraint-list-vars (append constrs1 constrs2))
           (set::union (constraint-list-vars constrs1)
                       (constraint-list-vars constrs2)))
    :induct t)

  (defrule constraint-list-vars-of-rev
    (equal (constraint-list-vars (rev constrs))
           (constraint-list-vars constrs))
    :induct t
    :enable set::union-symmetric))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define definition-free-vars ((def definitionp))
  :returns (vars name-setp)
  :short "Set of free variables in a definition."
  :long
  (xdoc::topstring
   (xdoc::p
    "These are the variables in the body minus the parameters."))
  (set::difference (constraint-list-vars (definition->body def))
                   (set::mergesort (definition->para def))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define lookup-definition ((name namep) (defs definition-listp))
  :returns (def? definition-optionp)
  :short "Look up a definition in a list of definitions."
  :long
  (xdoc::topstring
   (xdoc::p
    "If the list has a definition for the given name,
     return that definition.
     Otherwise return @('nil').")
   (xdoc::p
    "We return the first definition found for that name.
     In a well-formed lists of definitions,
     there is at most a definition for each name,
     and thus the first one found (if any) is also the only one."))
  (b* (((when (endp defs)) nil)
       (def (car defs))
       ((when (equal (definition->name def)
                     (name-fix name)))
        (definition-fix def)))
    (lookup-definition name (cdr defs)))
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fty::defprod constrel
  :short "Fixtype of relation constraints."
  :long
  (xdoc::topstring
   (xdoc::p
    "This is isomorphic to the @(':relation') kind of @(tsee constraint),
     but it is convenient to have a separate fixtype here,
     for certain purposes."))
  ((name name)
   (args expression-list))
  :pred constrelp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fty::defset constrel-set
  :short "Fixtype of sets of relation constraints."
  :elt-type constrel
  :elementp-of-nil nil
  :pred constrel-setp
  :fix constrel-sfix
  :equiv constrel-sequiv)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-constrels ((constr constraintp))
  :returns (crels constrel-setp)
  :short "Set of relation constraints in a constraint."
  :long
  (xdoc::topstring
   (xdoc::p
    "This is the empty set for an equality constraints;
     for a relation constraint, it is the singleton with that constraint,
     in @(tsee constrel) form.
     This function is used to define @(tsee constraint-list-constrels)."))
  (constraint-case constr
                   :equal nil
                   :relation (set::insert
                              (make-constrel :name constr.name
                                             :args constr.args)
                              nil))
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-list-constrels ((constrs constraint-listp))
  :returns (crels constrel-setp)
  :short "Set of relation constraints in a list of constraints."
  :long
  (xdoc::topstring
   (xdoc::p
    "In essence, we select the relation constraints
     and we turn them into the @(tsee constrel) form."))
  (cond ((endp constrs) nil)
        (t (set::union (constraint-constrels (car constrs))
                       (constraint-list-constrels (cdr constrs)))))
  :verify-guards :after-returns
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-rels ((constr constraintp))
  :returns (rels name-setp)
  :short "Set of (names of) relations in a constraint."
  :long
  (xdoc::topstring
   (xdoc::p
    "This is the empty set for an equality constraint;
     for a relation constraint,
     it is the singleton with that constraint relation.
     This function is used to define @(tsee constraint-list-rels)."))
  (constraint-case constr
                   :equal nil
                   :relation (set::insert constr.name nil))
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define constraint-list-rels ((constrs constraint-listp))
  :returns (rels name-setp)
  :short "Set of (names of) relations in a list of constraints."
  :long
  (xdoc::topstring
   (xdoc::p
    "We collect all the relation names."))
  (cond ((endp constrs) nil)
        (t (set::union (constraint-rels (car constrs))
                       (constraint-list-rels (cdr constrs)))))
  :verify-guards :after-returns
  :hooks (:fix))
