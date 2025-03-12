(lang dune 3.17)

(name dynamic_gc)

(generate_opam_files true)

(source
 (github semgrep/dynamic-gc))

(authors "Nat Mote <nat@semgrep.com>")

(maintainers "Nat Mote <nat@semgrep.com>")

(license MIT)

(documentation https://github.com/semgrep/dynamic-gc)

(package
 (name dynamic_gc)
 (synopsis "Dynamically adjust GC behavior based on memory usage")
 (description "A utility to dynamically adjust garbage collector behavior based
              on memory usage, allowing your application to prioritize improved
              run time when memory usage is low, but prioritize decreased memory
              usage when memory usage is high.")
 (depends (ocaml (>= 4.08.0)))
 (tags
  ("garbage collector" "gc")))
