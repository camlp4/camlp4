4.02+6
------

* add support for native toplevels
* add a check on the version of the compiler

4.02+5 (4.02.1+3)
------

* fix linking
* update license and headers

4.02+4 (4.02.1+2)
------

* fix parsing of phrases in the toplevel
* add `DESTDIR` support (patch by Olaf Hering)

4.02+3 (4.02.1+1)
------

* map `functor () ->` to `functor * ->` like OCaml
* fix hanging problem in the toplevel

4.02+2 (4.02.0+2)
------

* raise an error when passing "with type M.t := ..." to OCaml
* Make scripts insensitive to `CDPATH`
* fix build when ocamlopt is not available
* fix the default value of `PKGDIR`

4.02+1 (4.02.0+1)
------

* support the `M()` syntax
* support for extensible types
* support the `match ... with exception ...` syntax
