-- Copyright (c) 2017 Scott Morrison. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Authors: Scott Morrison

import .force .applicable .fsplit .automatic_induction .tidy_attributes .intro_at_least_one
import .chain
import .recover
import .rewrite_search
import .injections
import .if_then_else
import tactic.interactive

import data.list

universe variables u v

attribute [reducible] cast
attribute [reducible] lift_t coe_t coe_b has_coe_to_fun.coe
attribute [reducible] eq.mpr
attribute [ematch] subtype.property

meta def dsimp' := `[dsimp {unfold_reducible := tt, md := semireducible}]
meta def dsimp_all' := `[dsimp at * {unfold_reducible := tt, md := semireducible}]

lemma funext_simp {α : Type u} {Z : α → Type v} {f g : Π a : α, Z a} : (f = g) = ∀ a : α, f a = g a :=
begin
  apply propext,
  split,
  { intro w, intro, rw w },
  { intro w, apply funext, assumption }
end 

open tactic

-- remove these when https://github.com/leanprover/mathlib/pull/164 is merged
meta def symm_apply (e : expr) (cfg : apply_cfg := {}) : tactic (list (name × expr)) :=
tactic.apply e cfg <|> (symmetry >> tactic.apply e cfg)

meta def symm_apply_assumption
  (asms : option (list expr) := none)
  (tac : tactic unit := return ()) : tactic unit :=
do { ctx ← asms.to_monad <|> local_context,
     ctx.any_of (λ H, () <$ symm_apply H ; tac) } <|>
do { exfalso,
     ctx ← asms.to_monad <|> local_context,
     ctx.any_of (λ H, () <$ symm_apply H ; tac) }
<|> fail "assumption tactic failed"

-- TODO I'd love to do some profiling here, and find how much time is spent inside each tactic,
-- also divided up between successful and unsuccessful calls.

-- TODO also find tactics which are never used!

-- TODO split_ifs?
-- TODO refine_struct?

meta def simp_only_funext := `[simp only [funext_simp] at *] >> pure "simp only [funext_simp] at *"
meta def dsimp_reducible := `[dsimp {unfold_reducible:=tt}] >> pure "dsimp {unfold_reducible:=tt}"
meta def exact_decidable := `[exact dec_trivial]                        >> pure "exact dec_trivial"

meta def default_tidy_tactics : list (tactic string) :=
[
  force (reflexivity)                         >> pure "refl", 
  exact_decidable,
  semiapplicable                              >>= λ n, pure ("apply " ++ n.to_string ++ " ; assumption"),
  applicable                                  >>= λ n, pure ("apply " ++ n.to_string),
  `[ext]                                      >> pure "ext",
  intro_at_least_one                          >> pure "intros",
  automatic_induction,
  `[apply_auto_param]                         >> pure "apply_auto_param",
  `[unfold_coes]                              >> pure "unfold_coes",
  `[dsimp at *]                               >> pure "dsimp at *",
  `[simp at *]                                >> pure "simp at *",
  fsplit                                      >> pure "fsplit", 
  injections_and_clear                        >> pure "injections_and_clear",
  terminal_goal >> (`[solve_by_elim {discharger := `[symm_apply_assumption]}])  >> pure "solve_by_elim {discharger := `[cc]}",
  simp_only_funext             ,
  dsimp_reducible             ,
  run_tidy_tactics
]

meta structure tidy_cfg extends chain_cfg :=
( trace_result : bool    := ff )
( tactics : list (tactic string) := default_tidy_tactics )

meta def tidy ( cfg : tidy_cfg := {} ) : tactic unit :=
do
  results ← chain cfg.to_chain_cfg cfg.tactics,
  -- try tactic.interactive.resetI,      
  if cfg.trace_result then
    trace ("---\n" ++ (",\n".intercalate results) ++ "\n---")
  else
    tactic.skip

meta def obviously_tactics : list (tactic string) :=
[ tactic.interactive.rewrite_search_using `ematch ] -- TODO should switch this back to search eventually

meta def obviously : tactic unit := tidy { tactics := default_tidy_tactics ++ obviously_tactics }

meta def obviously'  : tactic unit := tidy { tactics := default_tidy_tactics ++ obviously_tactics, trace_result := tt }
meta def obviously'' : tactic unit := tidy { tactics := default_tidy_tactics ++ obviously_tactics, make_declarations := ff }

example : 1 = 1 := by obviously

instance subsingleton_pempty : subsingleton pempty := by tidy
instance subsingleton_punit  : subsingleton punit  := by tidy
