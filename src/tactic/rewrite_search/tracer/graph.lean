import tactic.iconfig
import tactic.rewrite_search.core
import tactic.rewrite_search.module

import system.io

open tactic.rewrite_search

namespace tactic.rewrite_search.tracer.graph

open tactic
open io.process.stdio

def SUCCESS_CHAR : string := "S"
def ERROR_CHAR   : string := "E"
def SEARCH_PATHS : list string := [
  "_target/deps/lean-rewrite-search/res/graph_tracer",
  "res/graph_tracer"
]

def get_app_path (dir : string) (app : string) : string :=
dir ++ "/" ++ app ++ ".py"

def args (dir : string) (app : string) : io.process.spawn_args := {
  cmd    := "python3",
  args   := [get_app_path dir app],
  stdin  := piped,
  stdout := piped,
  stderr := inherit,
  env    := [
    ("PYTHONPATH", some (dir ++ "/pygraphvis.zip/pygraphvis")),
    ("PYTHONIOENCODING", "utf-8")
  ],
}

structure visualiser :=
(proc : io.proc.child)
meta def visualiser.publish (v : visualiser) (f : format) : tactic unit :=
tactic.unsafe_run_io $ do
  io.fs.write v.proc.stdin (f.to_string.to_char_buffer.push_back '\n'),
  io.fs.flush v.proc.stdin
meta def visualiser.pause (v : visualiser) : tactic unit :=
tactic.unsafe_run_io (do io.fs.read v.proc.stdout 1, return ())

def file_exists (path : string) : io bool := do
  c ← io.proc.spawn { cmd := "test", args := ["-f", path] },
  retval ← io.proc.wait c,
  return (retval = 0)

inductive spawn_result
| success : io.proc.child → spawn_result -- Client launched and the client reported success status
| abort : string → spawn_result          -- Client launched and we got a bad response code
| failure                                -- Could not launch client
| missing                                -- The script we tried to launch does't exist

meta def read_until_nl (h : io.handle) : io string := do
  c ← io.fs.read h 1,
  match c.to_list with
  | ['\n'] := return ""
  | [c]    := do r ← read_until_nl, return (c.to_string ++ r)
  | _      := return ""
  end

meta def try_launch_with_path (path : string) : io spawn_result := do
  ex ← file_exists (get_app_path path "client"),
  if ex then do
    c ← io.proc.spawn (args path "client"),
    buff ← io.fs.read c.stdout 1,
    str ← pure buff.to_string,
    if str = SUCCESS_CHAR then
      return (spawn_result.success c)
    else if str = ERROR_CHAR then do
      reason ← read_until_nl c.stdout,
      return (spawn_result.abort reason)
    else if str = "" then
      return spawn_result.failure
    else
      return $ spawn_result.abort (format!"bug: unknown client status character \"{str}\"").to_string
  else
    return spawn_result.missing

meta def try_launch_with_paths : list string → io spawn_result
| []          := return spawn_result.failure
| (p :: rest) := do
  sr ← try_launch_with_path p,
  match sr with
  | spawn_result.missing := try_launch_with_paths rest
  | _                    := return sr
  end

meta def diagnose_launch_failure : io string := do
  c ← io.proc.spawn { cmd := "python3", args := ["--version"], stdin := piped, stdout := piped, stderr := piped },
  r ← io.proc.wait c,
  match r with
  | 255 := return "python3 is missing, and the graph visualiser requires it. Please install python3."
  | 0   := return "bug: python3 present but could not launch client!"
  | ret := return (format!"bug: unexpected return code {ret} during launch failure diagnosis").to_string
  end

meta def init : tactic (init_result visualiser) :=
do c ← tactic.unsafe_run_io (try_launch_with_paths SEARCH_PATHS),
   match c with
   | spawn_result.success c    :=
     let vs : visualiser := ⟨c⟩ in do
     vs.publish "S", init_result.pure vs
   | spawn_result.abort reason :=
     init_result.fail ("Abort! " ++ reason)
   | spawn_result.failure      := do
     reason ← tactic.unsafe_run_io diagnose_launch_failure,
     init_result.fail ("Failure! " ++ reason)
   | spawn_result.missing      :=
     init_result.fail "Error! bug: could not determine client location"
   end

meta def publish_vertex (vs : visualiser) (v : vertex) : tactic unit :=
vs.publish format!"V|{v.id.to_string}|{v.s.to_string}|{v.id}"

meta def publish_edge (vs : visualiser) (e : edge) : tactic unit :=
vs.publish format!"E|{e.f.to_string}|{e.t.to_string}"

meta def publish_visited (vs : visualiser) (v : vertex) : tactic unit :=
vs.publish format!"B|{v.id.to_string}"

meta def publish_finished (vs : visualiser) (es : list edge) : tactic unit :=
do es.mmap' (λ e : edge, vs.publish format!"F|{e.f.to_string}|{e.t.to_string}"),
   vs.publish format!"D"

meta def dump (vs : visualiser) (str : string) : tactic unit :=
vs.publish (str ++ "\n")

meta def pause (vs : visualiser) : tactic unit :=
vs.pause

end tactic.rewrite_search.tracer.graph

namespace tactic.rewrite_search.tracer

open tactic.rewrite_search.tracer.graph

meta def graph_cnst := λ α β γ,
tracer.mk α β γ graph.init graph.publish_vertex graph.publish_edge graph.publish_visited graph.publish_finished graph.dump graph.pause

meta def graph : tactic expr := generic `tactic.rewrite_search.tracer.graph_cnst

meta def visualiser_cfg (_ : name) : cfgtactic unit :=
  iconfig.publish `tracer $ cfgopt.value.pexpr $ expr.const `graph []

iconfig_add rewrite_search [
  tracer.graph : custom visualiser_cfg
  visualiser   : custom visualiser_cfg
]

end tactic.rewrite_search.tracer
