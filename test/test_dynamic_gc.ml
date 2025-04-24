(*
 * Copyright (C) 2024-2025 Semgrep, Inc.
 *
 * This source code is licensed under the MIT license found in the LICENSE file
 * in the root directory of this source tree.
 *)

(* If this grows any more complex, pull in Alcotest and Testo *)
let check (expected: int) (actual: int) (case_name: string) =
  if expected <> actual then
    failwith (Printf.sprintf "%s: expected %d, got %d" case_name expected actual)

(* name, config, heap size, expected space overhead *)
type case = string * DynamicGc.config * int * int

let simple_config =
  DynamicGc.
    {
      min_space_overhead = 20;
      max_space_overhead = 40;
      heap_start_worrying_mb = 1_024;
      heap_really_worry_mb = 4_096;
    }

let same_heap_size_cutoff =
  DynamicGc.Config.simple ~threshold_mb:1_024

let cases : case list =
  [
    ("under worrying limit", simple_config, 512, 40);
    ("at worrying limit", simple_config, 1_024, 40);
    ("halfway", simple_config, 2_560, 30);
    ("at really worrying limit", simple_config, 4_096, 20);
    ("above really worrying limit", simple_config, 8_192, 20);
    ("below single cutoff", same_heap_size_cutoff, 1_023, 120);
    ("at single cutoff", same_heap_size_cutoff, 1_024, 120);
    ("above single cutoff", same_heap_size_cutoff, 1_025, 80);
  ]

let check_case (name, config, heap_size, expected_space_overhead) =
  check
    expected_space_overhead
    (DynamicGc.ForTestingDoNotUse.space_overhead_of_heap_size config heap_size)
    name

let () = List.iter check_case cases
