# Dynamic GC
Dynamic tuning for the OCaml garbage collector.

This utility allows you to instruct the OCaml garbage collector to become more
aggressive as the size of the major heap grows. This can be useful if you would
prefer your application to execute quickly with few resources dedicated to
garbage collection when memory usage is low, but would like to change that
trade-off when memory usage is high.

Specifically, this utility adjusts the `space_overhead` value at the end of each
major collection using the [`Gc`](https://ocaml.org/manual/5.3/api/Gc.html)
module.

We used this to [upgrade Semgrep from OCaml 4 to OCaml
5](https://semgrep.dev/blog/2025/upgrading-semgrep-from-ocaml-4-to-ocaml-5/)
without introducing memory consumption or time regressions.

## Usage

Install via `opam install dynamic_gc`.

Use according to
[`DynamicGc.mli`](https://github.com/semgrep/dynamic-gc/blob/main/lib/DynamicGc.mli).

For example, you might put the following at or near the entry point to your
program. It would allow `space_overhead` to range between 20 and 40, such that
it is 40 when the size of the major heap is less than 2 GB, 20 when the size of
the major heap is greater than 4 GB, and linearly interpolated in between.

```
DynamicGc.(setup_dynamic_tuning
  {
    min_space_overhead = 20;
    max_space_overhead = 40;
    heap_start_worrying_mb = 2_048;
    heap_really_worry_mb = 4_096;
  });
```

## Caveats

This tunes the garbage collector based on the size of the major heap, not the
amount of memory that is currently live. Because OCaml 5 does not do compaction
by default, this means that if your program uses a lot of memory and then
releases it, the garbage collector may still be set to an aggressive setting
because the major heap is still large. You may need to manually call
[`Gc.compact ()`](https://ocaml.org/manual/5.3/api/Gc.html#VALcompact) in order
to free memory and reduce the size of the major heap, thereby allowing this
utility to increase the value of `space_overhead`.

This utility relies on garbage collector alarms. This functionality is [broken
in OCaml
5.2.0](https://discuss.ocaml.org/t/changes-in-handling-of-gc-parameters-and-alarms-in-5-2-0/14986).
Upgrade to 5.2.1 instead to use this utility.

## Contributing

To build: `dune build`

To test: `dune test`

To use your local copy in another project: `opam pin .`
