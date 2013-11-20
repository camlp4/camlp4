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

OB := ocamlbuild -no-ocamlfind

include Makefile.config

A := $(ext_lib)
O := $(ext_obj)

ifeq ($(os_type),Win32)
EXE := .exe
else
EXE :=
endif

# +------------------------------------------------------------------+
# | Targets                                                          |
# +------------------------------------------------------------------+

CAMLP4_BYTE := \
	camlp4/Camlp4.cmo \
	camlp4/Camlp4Top.cmo \
	camlp4/camlp4prof.byte$(EXE) \
	camlp4/mkcamlp4.byte$(EXE) \
	camlp4/camlp4.byte$(EXE) \
	camlp4/camlp4fulllib.cma

CAMLP4_NATIVE := \
	camlp4/Camlp4.cmx \
	camlp4/Camlp4Top.cmx \
	camlp4/camlp4prof.native$(EXE) \
	camlp4/mkcamlp4.native$(EXE) \
	camlp4/camlp4.native$(EXE) \
	camlp4/camlp4fulllib.cmxa

CAMLP4_PROGS := camlp4boot camlp4r camlp4rf camlp4o camlp4of camlp4oof camlp4orf
CAMLP4_BYTE := $(CAMLP4_BYTE) \
	$(CAMLP4_PROGS:%=camlp4/%.byte$(EXE)) \
	$(CAMLP4_PROGS:%=camlp4/%.cma)
CAMLP4_NATIVE := $(CAMLP4_NATIVE) \
	$(CAMLP4_PROGS:%=camlp4/%.native$(EXE))

CAMLP4_PLUGIN_DIRS := Camlp4Parsers Camlp4Printers Camlp4Filters
CAMLP4_PLUGINS := $(wildcard $(CAMLP4_PLUGIN_DIRS:%=camlp4/%/*.ml))
CAMLP4_BYTE := $(CAMLP4_BYTE) \
	$(patsubst %.ml,%.cmo,$(CAMLP4_PLUGINS))
CAMLP4_NATIVE := $(CAMLP4_NATIVE) \
	$(patsubst %.ml,%.cmx,$(CAMLP4_PLUGINS)) \
	$(patsubst %.ml,%$(O),$(CAMLP4_PLUGINS))

.PHONY: default
default: byte

.PHONY: byte
byte:
	$(OB) $(CAMLP4_BYTE)

.PHONY: native
native:
	$(OB) $(CAMLP4_NATIVE)

.PHONY: all
all:
	$(OB) $(CAMLP4_BYTE) $(CAMLP4_NATIVE)

.PHONY: clean
clean:
	$(OB) -clean

.PHONY: distclean
distclean: clean
	rm -f myocamlbuild_config.ml Makefile.config
