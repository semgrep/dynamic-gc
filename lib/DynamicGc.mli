(*
 * Copyright (C) 2024-2025 Semgrep, Inc.
 *
 * This source code is licensed under the MIT license found in the LICENSE file
 * in the root directory of this source tree.
 *)

(* Utilities for interacting with the OCaml garbage collector. See
 * https://ocaml.org/manual/5.2/api/Gc.html for context. Without familiarity
 * with the Gc module, this module is not likely to make a whole lot of sense.
 * *)

(* Configuration for dynamic GC tuning. This allows us to prioritize time over
 * space by minimizing time spent garbage collecting when the major heap is
 * small. As the major heap grows, we can gradually make the GC more aggressive
 * and begin to prioritize space efficiency at the expense of time. *)
type config = {
  (* The minimum value for space_overhead that should be dynamically applied.
   * This is the MOST aggressive GC setting. *)
  min_space_overhead : int;
  (* The maximum setting for space_overhead that should be dynamically applied.
   * This is the LEAST aggressive GC setting. *)
  max_space_overhead : int;
  (* The size of the major heap where we start becoming more aggressive with
   * space_overhead. Below this size, we always set space_overhead to
   * max_space_overhead. Above, we interpolate linearly until we reach
   * min_space_overhead at heap_really_worry_mb. *)
  heap_start_worrying_mb : int;
  (* The size of the major heap where we apply the most aggressive setting for
   * space_overhead (min_space_overhead) in an attempt to minimize memory
   * consumption at the cost of runtime. *)
  heap_really_worry_mb : int;
}

(* Starts dynamic GC tuning based on the given config. Recomputes and applies
 * the desired space_overhead after each major collection.
 *
 * Precondition: As this mutates global state, it cannot be called multiple
 * times without intervening calls to `stop_dynamic_tuning`. *)
val setup_dynamic_tuning : config -> unit

(* Stops the ongoing dynamic GC tuning. Does not return space_overhead to its
 * previous value.
 *
 * Precondition: Cannot be called unless dynamic tuning is currently ongoing. *)
val stop_dynamic_tuning : unit -> unit

module ForTestingDoNotUse : sig
  val space_overhead_of_heap_size : config -> int -> int
end
