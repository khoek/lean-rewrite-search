import logic.basic
import tidy.tidy
import tidy.rewrite_search.discovery
open tidy.rewrite_search.tracer
open tidy.rewrite_search.metric

local attribute [instance] classical.prop_decidable

@[suggest] private def use_logic := `logic

example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
calc
        ((B → C) → (¬(A → C)     ∧ ¬(A ∨ B)))
      = ((B → C) → (¬(¬A ∨ C)    ∧ ¬(A ∨ B)))         : by rw ← imp_iff_not_or
  ... = ((B → C) → ((¬(¬A) ∧ ¬C) ∧ ¬(A ∨ B)))         : by rw not_or_distrib
  ... = ((B → C) → ((¬(¬A) ∧ ¬C) ∧ (¬A ∧ ¬B)))        : by rw not_or_distrib
  ... = ((B → C) → ((A ∧ ¬C) ∧ (¬A ∧ ¬B)))            : by rw not_not
  ... = ((B → C) → ((A ∧ ¬C) ∧ ¬A ∧ ¬B))              : by rw and_assoc
  ... = ((B → C) → ((¬C ∧ A) ∧ ¬A ∧ ¬B))              : by rw and_comm (A) (¬C)
  ... = ((B → C) → (¬C ∧ A ∧ ¬A ∧ ¬B))                : by rw and_assoc
  ... = ((B → C) → (¬C ∧ (A ∧ ¬A) ∧ ¬B))              : by rw and_assoc
  ... = ((B → C) → (¬C ∧ ¬ B ∧ (A ∧ ¬A)))             : by rw and_comm (¬ B) (A ∧ ¬A)
  ... = ((B → C) → (¬C ∧ ¬ B ∧ false ))               : by rw and_not_self_iff A
  ... = ((B → C) → ((¬C) ∧ false ))                   : by rw and_false
  ... = ((B → C) → (false))                           : by rw and_false
  ... = (¬(B → C) ∨ false)                            : by rw imp_iff_not_or
  ... = ¬(B → C)                                      : by rw or_false
  ... = ¬(¬B ∨ C)                                     : by rw imp_iff_not_or
  ... = ((¬¬B) ∧ (¬C))                                : by rw not_or_distrib
  ... = (B ∧ ¬C)                                      : by rw not_not

-- local attribute [search] imp_iff_not_or not_or_distrib not_not and_assoc and_comm and_not_self_iff and_false not_not

-- Seems like SVM is good at these logic problems

example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) := by rewrite_search

example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
  by rewrite_search {suggest := [`logic]}

example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
  by rewrite_search_using []

-- Vanilla
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt}

-- CM
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt, metric := edit_distance {refresh_freq := 10} weight.cm}

-- libSVM refresh every 20
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt, metric := edit_distance {refresh_freq := 20} weight.svm}

-- libSVM refresh every 15
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt, metric := edit_distance {refresh_freq := 15} weight.svm}

-- libSVM refresh every 10
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt, metric := edit_distance {refresh_freq := 10} weight.svm}

-- libSVM refresh every 5
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, trace_summary := tt, metric := edit_distance {refresh_freq := 5} weight.svm}

-- libSVM refresh every 1
example {A B C : Prop} : ((B → C) → (¬(A → C) ∧ ¬(A ∨ B))) = (B ∧ ¬C) :=
by
  rewrite_search {view := no visualiser, strategy := tidy.rewrite_search.strategy.pexplore {pop_size := 1}, trace_summary := tt, metric := edit_distance {refresh_freq := 1} weight.svm}

-- Theorem Proving in Lean

-- 3.6. Exercises

namespace q1
  open classical

  variables p q r s : Prop

  -- commutativity of ∧ and ∨
  example : p ∧ q ↔ q ∧ p := by obviously
  -- example : p ∨ q ↔ q ∨ p := by obviously

  -- associativity of ∧ and ∨
  example : (p ∧ q) ∧ r ↔ p ∧ (q ∧ r) := by obviously
  -- example : (p ∨ q) ∨ r ↔ p ∨ (q ∨ r) := by obviously

  -- distributivity
  -- example : p ∧ (q ∨ r) ↔ (p ∧ q) ∨ (p ∧ r) := by obviously
  -- example : p ∨ (q ∧ r) ↔ (p ∨ q) ∧ (p ∨ r) := by obviously

  -- other properties
  example : (p → (q → r)) ↔ (p ∧ q → r) := by obviously
  -- example : ((p ∨ q) → r) ↔ (p → r) ∧ (q → r) := by obviously
  -- example : ¬(p ∨ q) ↔ ¬p ∧ ¬q := by obviously
  example : ¬p ∨ ¬q → ¬(p ∧ q) := by obviously
  example : ¬(p ∧ ¬p) := by obviously
  example : p ∧ ¬q → ¬(p → q) := by obviously
  example : ¬p → (p → q) := by obviously
  example : (¬p ∨ q) → (p → q) := by obviously
  example : p ∨ false ↔ p := by obviously
  example : p ∧ false ↔ false := by obviously
  example : ¬(p ↔ ¬p) := by obviously
  example : (p → q) → (¬q → ¬p) := by obviously

  -- these require classical reasoning
  -- example : (p → r ∨ s) → ((p → r) ∨ (p → s)) := by obviously
  -- example : ¬(p ∧ q) → ¬p ∨ ¬q := by obviously
  example : ¬(p → q) → p ∧ ¬q := by obviously
  -- example : (p → q) → (¬p ∨ q) := by obviously
  -- example : (¬q → ¬p) → (p → q) := by obviously
  -- example : p ∨ ¬p := by obviously
  -- example : (((p → q) → p) → p) := by obviously
end q1

-- 4.6. Exercises

namespace q1
  variables (α : Type) (p q : α → Prop)

  example : (∀ x, p x ∧ q x) ↔ (∀ x, p x) ∧ (∀ x, q x) := by obviously
  example : (∀ x, p x → q x) → (∀ x, p x) → (∀ x, q x) := by obviously
  -- example : (∀ x, p x) ∨ (∀ x, q x) → ∀ x, p x ∨ q x := by obviously
end q1

namespace q2
  variables (α : Type) (p q : α → Prop)
  variable r : Prop

  example : α → ((∀ x : α, r) ↔ r) := by obviously
  -- example : (∀ x, p x ∨ r) ↔ (∀ x, p x) ∨ r := by obviously
  example : (∀ x, r → p x) ↔ (r → ∀ x, p x) := by obviously
end q2

-- Barber paradox:
namespace q3
  variables (men : Type) (barber : men)
  variable  (shaves : men → men → Prop)

  example (h : ∀ x : men, shaves barber x ↔ ¬ shaves x x) : false := by obviously
end q3

namespace q5
  open classical

  variables (α : Type) (p q : α → Prop)
  variable a : α
  variable r : Prop

  example : (∃ x : α, r) → r := by obviously
  -- example : r → (∃ x : α, r) := by obviously
  example : (∃ x, p x ∧ r) ↔ (∃ x, p x) ∧ r := by obviously
  -- example : (∃ x, p x ∨ q x) ↔ (∃ x, p x) ∨ (∃ x, q x) := by obviously

  example : (∀ x, p x) ↔ ¬ (∃ x, ¬ p x) := by obviously
  example : (∃ x, p x) ↔ ¬ (∀ x, ¬ p x) := by obviously
  example : (¬ ∃ x, p x) ↔ (∀ x, ¬ p x) := by obviously
  -- example : (¬ ∀ x, p x) ↔ (∃ x, ¬ p x) := by obviously

  example : (∀ x, p x → r) ↔ (∃ x, p x) → r := by obviously
  -- example : (∃ x, p x → r) ↔ (∀ x, p x) → r := by obviously
  -- example : (∃ x, r → p x) ↔ (r → ∃ x, p x) := by obviously
end q5

namespace q6
  variables (real : Type) [ordered_ring real]
  variables (log exp : real → real)
  variable  log_exp_eq : ∀ x, log (exp x) = x
  variable  exp_log_eq : ∀ {x}, x > 0 → exp (log x) = x
  variable  exp_pos    : ∀ x, exp x > 0
  variable  exp_add    : ∀ x y, exp (x + y) = exp x * exp y

  -- this ensures the assumptions are available in tactic proofs
  include log_exp_eq exp_log_eq exp_pos exp_add

  example (x y z : real) :
    exp (x + y + z) = exp x * exp y * exp z :=
  by rw [exp_add, exp_add]

  example (y : real) (h : y > 0) : exp (log y) = y :=
  exp_log_eq h

  -- theorem log_mul {x y : real} (hx : x > 0) (hy : y > 0) :
  --   log (x * y) = log x + log y :=
  -- by rewrite_search {discharger := assumption}
end q6

-- 5.8. Exercises

namespace q2
  -- example (p q r : Prop) (hp : p) :
  -- (p ∨ q ∨ r) ∧ (q ∨ p ∨ r) ∧ (q ∨ r ∨ p) :=
  -- by obviously
end q2
