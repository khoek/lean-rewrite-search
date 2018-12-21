import tactic.rewrite_search.core
import tactic.rewrite_search.module

-- The trivial metric: I just report that every vertex is distance zero from every other.

open tactic.rewrite_search

namespace tactic.rewrite_search.metric.trivial

variables {α δ : Type} (g : search_state α unit unit δ)

meta def trivial_init : tactic (init_result unit) := init_result.pure ()
meta def trivial_update (itr : ℕ) : tactic (search_state α unit unit δ) := return g
meta def trivial_init_bound (_ : search_state α unit unit δ) (l r : vertex) : bound_progress unit := bound_progress.exactly 0 ()
meta def trivial_improve_estimate_over (_ : search_state α unit unit δ) (m : dnum) (l r : vertex) (bnd : bound_progress unit) : bound_progress unit := bound_progress.exactly 0 ()

end tactic.rewrite_search.metric.trivial

namespace tactic.rewrite_search.metric

open tactic.rewrite_search.metric.trivial

meta def trivial_cnst := λ α δ, @metric.mk α unit unit δ trivial_init trivial_update trivial_init_bound trivial_improve_estimate_over

meta def trivial : tactic expr :=
  generic ``tactic.rewrite_search.metric.trivial_cnst

meta def trivial_cfg (_ : name) : cfgtactic unit :=
  iconfig.publish `metric $ cfgopt.value.pexpr $ expr.const `trivial []

iconfig_add rewrite_search [ metric.trivial : custom trivial_cfg ]

end tactic.rewrite_search.metric
