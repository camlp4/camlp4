#########################################################################
#                                                                       #
#                                 OCaml                                 #
#                                                                       #
#            Xavier Leroy, projet Cristal, INRIA Rocquencourt           #
#                                                                       #
#   Copyright 1999 Institut National de Recherche en Informatique et    #
#   en Automatique.  All rights reserved.  This file is distributed     #
#   under the terms of the Q Public License version 1.0.                #
#                                                                       #
#########################################################################

# The main Makefile

OB := ocamlbuild -no-ocamlfind -classic-display

.PHONY: default
default: byte

.PHONY: byte
byte:
	$(OB) `./build/camlp4-byte-only.sh`

.PHONY: native
native:
	$(OB) `./build/camlp4-native-only.sh`

.PHONY: all
all: byte native

.PHONY: install
install:
	./build/install.sh

.PHONY: bootstrap
bootstrap:
	./build/camlp4-bootstrap.sh

.PHONY: Camlp4Ast
Camlp4Ast:
	./build/camlp4-mkCamlp4Ast.sh

.PHONY: clean
clean:
	rm -rf _build

.PHONY: distclean
distclean:
	rm -rf _build myocamlbuild_config.ml Makefile.config
