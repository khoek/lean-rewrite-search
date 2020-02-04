import data.list
import tactic.where

import lib.string

namespace binder

meta def set_name : binder → _root_.name → binder
| ⟨_, bi, e⟩ n := ⟨n, bi, e⟩

meta def set_type : binder → expr → binder
| ⟨n, bi, _⟩ e := ⟨n, bi, e⟩

meta def set_binder_info : binder → _root_.binder_info → binder
| ⟨n, _, e⟩ bi := ⟨n, bi, e⟩

meta def pretty_print : binder → tactic string
| ⟨n, bi, e⟩ := let brackets := bi.brackets in do
  ppe ← to_string <$> tactic.pp e,
  return $ brackets.1 ++ n.to_string ++ " : " ++ ppe ++ brackets.2

private meta def instantiate_list_aux : list binder → list binder → list binder
| seen [] := seen
| seen (⟨n, bi, e⟩ :: rest) :=
  let e := e.instantiate_vars $ seen.reverse.map $ λ v, expr.const v.1 [] in
  instantiate_list_aux (seen.concat ⟨n, bi, e⟩) rest

meta def instantiate_list : list binder → list binder :=
  instantiate_list_aux []

meta def instantiate (e : expr) (l : list binder) : expr :=
  e.instantiate_vars $ l.reverse.map $ λ v : binder, expr.const v.1 []

meta def drop_implicit : binder → option binder
| ⟨n, binder_info.default, e⟩ := some ⟨n, binder_info.default, e⟩
| _ := none

meta def list_to_args (l : list binder) (drop_impl : bool := tt) : tactic string := do
  l ← (instantiate_list l).mmap binder.pretty_print,
  return $ string.intercalate " " l

meta def list_to_invocation (l : list binder) (drop_impl : bool := tt) : string :=
  let l := if drop_impl then l.filter_map drop_implicit else l in
  string.intercalate " " $ (instantiate_list l).map $ to_string ∘ binder.name

end binder

namespace expr

private meta def unroll_pi_binders_aux : list binder → expr → list binder × expr
| curr (expr.pi var_n bi var_type rest) :=
  unroll_pi_binders_aux (curr.concat ⟨var_n, bi, var_type⟩) rest
| curr ex := (curr, ex)

meta def unroll_pi_binders : expr → list binder × expr :=
  unroll_pi_binders_aux []

private meta def unroll_lam_binders_aux : list binder → expr → list binder × expr
| curr (expr.lam var_n bi var_type rest) :=
  unroll_lam_binders_aux (curr.concat ⟨var_n, bi, var_type⟩) rest
| curr ex := (curr, ex)

meta def unroll_lam_binders : expr → list binder × expr :=
  unroll_lam_binders_aux []

end expr

namespace app

meta def count : expr → ℕ
| (expr.app e _) := 1 + count e
| _              := 0

meta def pop_n : expr → ℕ → expr
| e 0 := e
| (expr.app e _) n := pop_n e (n - 1)
| e _ := e

meta def pop (e : expr) : expr := pop_n e 1

meta def get_arg : expr → option expr
| (expr.app _ f) := some f
| _              := none

meta def chop : expr → option (name × list level × list expr)
| (expr.const n us) := some (n, us, [])
| (expr.app e v) :=
  match chop e with
  | none   := none
  | some (n, us, vs) := some (n, us, (v :: vs))
  end
| _ := none

meta def name (e : expr) : option name :=
  match chop e with
  | none := none
  | some (n, _, _) := n
  end

end app

namespace structure_instance

meta def extract_nth_field (st : expr) (n : ℕ) : option expr :=
  app.get_arg $ app.pop_n st ((app.count st) - (n + 1))

meta def extract_field (st : expr) (pi : environment.projection_info) : option expr :=
  extract_nth_field st (pi.nparams + pi.idx)

end structure_instance
