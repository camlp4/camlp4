camlp4
======

Camlp4 was a software system for writing extensible parsers for
programming languages. Since August 2019, Camlp4 is no longer
actively maintained and the last release to support all
OCaml language features was 4.08.

Later releases will try to keep camlp4 buildable, by supporting
new OCaml AST but not new syntax constructions, which means camlp4
will be able to parse only OCaml language up to 4.08.
Rationale: existing code using camlp4 will still be buildable,
but no new code should be written with camlp4.

Maintainers of Camlp4-using projects are encouraged to switch
to other systems:

- For new projects or actively-moving projects, we recommend adopting
  ppx attributes and extensions, which is now the preferred way to
  perform AST transformations on OCaml programs.

- For slow-moving projects or users of other Camlp4 features
  (extensible grammars), switching to the (maintained)
  [Camlp5](https://github.com/camlp5/camlp5) variant of the
  preprocessor should be easy.

Building from git
-----------------

Camlp4 branches try to follow OCaml ones. To build with the trunk of
OCaml, you need to use the trunk branch of Camlp4. To build for a
specific version, for instance 4.02.1, use the 4.02 branch of Camlp4.
