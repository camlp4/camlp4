camlp4
======

Camlp4 was a software system for writing extensible parsers for
programming languages. Since August 2019, Camlp4 is no longer
maintained. The last release of Camlp4 was the 4.08
release. Maintainers of Camlp4-using projects are encouraged to switch
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

Of cource, this was true until 4.08. The trunk branch of Camlp4 builds
with 4.08 only.
