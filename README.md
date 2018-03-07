camlp4
======

Camlp4 was a software system for writing extensible parsers for
programming languages. Since 2017, Camlp4 is not actively maintained
anymore, and only receives occasional fixes for compatibility with new
OCaml versions. Maintainers of Camlp4-using projects are actively
encouraged to switch to other systems:

- For new projects or actively-moving projects, we recommend adopting
  ppx attributes and extensions, which is now the preferred way to
  perform AST transformations on OCaml programs.

- For slow-moving projects or users of other Camlp4 features
  (extensible grammars), switching to the (maintained)
  [Camlp5](https://github.com/camlp5/camlp5) variant of the
  preprocessor should be easy.

Unless you are interested in taking over maintainance of Camlp4, we
prefer not to receive request for new features or changes --
contribution efforts should rather go to the ppx ecosystem or
Camlp5. Minor patches to improve compatibility with new OCaml versions
are welcome.

Building from git
-----------------

Camlp4 branches try to follow OCaml ones. To build with the trunk of
OCaml, you need to use the trunk branch of Camlp4. To build for a
specific version, for instance 4.02.1, use the 4.02 branch of Camlp4.
