(*
 * Copyright (C) 2024-2025 Semgrep, Inc.
 *
 * This source code is licensed under the MIT license found in the LICENSE file
 * in the root directory of this source tree.
 *)

let alarm : Gc.alarm option ref = ref None

type config = {
  min_space_overhead : int;
  max_space_overhead : int;
  heap_start_worrying_mb : int;
  heap_really_worry_mb : int;
}

let space_overhead_of_heap_size config heap_size_mb =
  if config.heap_start_worrying_mb = config.heap_really_worry_mb then begin
    (* Avoid a division by zero *)
    if heap_size_mb > config.heap_start_worrying_mb then
      config.min_space_overhead
    else config.max_space_overhead
  end
  else
    (* Linear interpolation *)
    let heap_size_mb = Float.of_int heap_size_mb in
    let min_space_overhead = Float.of_int config.min_space_overhead in
    let max_space_overhead = Float.of_int config.max_space_overhead in
    let heap_start_worrying_mb = Float.of_int config.heap_start_worrying_mb in
    let heap_really_worry_mb = Float.of_int config.heap_really_worry_mb in
    let rate =
      (min_space_overhead -. max_space_overhead)
      /. (heap_really_worry_mb -. heap_start_worrying_mb)
    in
    let intercept = max_space_overhead -. (rate *. heap_start_worrying_mb) in
    let space_overhead_unbounded = (rate *. heap_size_mb) +. intercept in
    let space_overhead =
      max min_space_overhead (min space_overhead_unbounded max_space_overhead)
    in
    space_overhead |> Float.round |> Float.to_int

let handle_alarm config () =
  let { Gc.heap_words; _ } = Gc.quick_stat () in
  let word_size_bytes = Sys.word_size / 8 in
  let heap_size_mb = heap_words * word_size_bytes / (1_024 * 1_024) in
  let space_overhead = space_overhead_of_heap_size config heap_size_mb in
  Gc.set { (Gc.get ()) with space_overhead }

let setup_dynamic_tuning config =
  if Option.is_some !alarm then
    failwith "Gc_.setup_dynamic_tuning called multiple times.";
  (* Can be the same, but that would be kind of stupid *)
  if config.min_space_overhead > config.max_space_overhead then
    failwith
      "Gc_.setup_dynamic_tuning called with min_space_overhead greater than \
       max_space_overhead";
  (* Can be equal if you want a sharp cutover from max space overhead to min! *)
  if config.heap_start_worrying_mb > config.heap_really_worry_mb then
    failwith
      "Gc_.setup_dynamic_tuning called with nonsensical heap size arguments";
  (* Call this immediately so that we set space_overhead as desired without
   * first having to wait for a major collection to complete. *)
  handle_alarm config ();
  alarm := Some (Gc.create_alarm (handle_alarm config))

let stop_dynamic_tuning () =
  match !alarm with
  | Some a ->
      Gc.delete_alarm a;
      alarm := None
  | None ->
      failwith
        "Gc_.stop_dynamic_tuning called when dynamic tuning was already \
         stopped."

module Config = struct
  let simple ~threshold_mb = {
    min_space_overhead = 80;
    max_space_overhead = 120;
    heap_start_worrying_mb = threshold_mb;
    heap_really_worry_mb = threshold_mb;
  }
end

module ForTestingDoNotUse = struct
  let space_overhead_of_heap_size = space_overhead_of_heap_size
end
