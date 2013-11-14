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

include config/Makefile
include stdlib/StdlibModules

CAMLP4_COMMON="\
  camlp4/Camlp4/Camlp4Ast.partial.ml \
  camlp4/boot/camlp4boot.byte"
CAMLP4_BYTE="$CAMLP4_COMMON \
  camlp4/Camlp4.cmo \
  camlp4/Camlp4Top.cmo \
  camlp4/camlp4prof.byte$EXE \
  camlp4/mkcamlp4.byte$EXE \
  camlp4/camlp4.byte$EXE \
  camlp4/camlp4fulllib.cma"
CAMLP4_NATIVE="$CAMLP4_COMMON \
  camlp4/Camlp4.cmx \
  camlp4/Camlp4Top.cmx \
  camlp4/camlp4prof.native$EXE \
  camlp4/mkcamlp4.native$EXE \
  camlp4/camlp4.native$EXE \
  camlp4/camlp4fulllib.cmxa"

for i in camlp4boot camlp4r camlp4rf camlp4o camlp4of camlp4oof camlp4orf; do
  CAMLP4_BYTE="$CAMLP4_BYTE camlp4/$i.byte$EXE camlp4/$i.cma"
  CAMLP4_NATIVE="$CAMLP4_NATIVE camlp4/$i.native$EXE"
done

cd camlp4
for dir in Camlp4Parsers Camlp4Printers Camlp4Filters; do
  for file in $dir/*.ml; do
    base=camlp4/$dir/`basename $file .ml`
    CAMLP4_BYTE="$CAMLP4_BYTE $base.cmo"
    CAMLP4_NATIVE="$CAMLP4_NATIVE $base.cmx $base.$O"
  done
done
cd ..


CAMLC=boot/ocamlrun boot/ocamlc -nostdlib -I boot
CAMLOPT=$(CAMLOPT_BIN) -nostdlib -I stdlib -I otherlibs/dynlink
COMPFLAGS=-strict-sequence -w +33..39 -warn-error A $(INCLUDES)
LINKFLAGS=
SWITCH_COMPILER=cd $(ROOTDIR)/config && $(MAKE) -f Makefile.switch-compiler

CAMLYACC=boot/ocamlyacc
YACCFLAGS=-v
CAMLLEX=boot/ocamlrun boot/ocamllex
CAMLDEP=boot/ocamlrun tools/ocamldep
DEPFLAGS=$(INCLUDES)
SHELL=/bin/sh
MKDIR=mkdir -p

CAMLP4OUT=$(WITH_CAMLP4:=out)
CAMLP4OPT=$(WITH_CAMLP4:=opt)

OCAMLBUILDBYTE=$(WITH_OCAMLBUILD:=.byte)
OCAMLBUILDNATIVE=$(WITH_OCAMLBUILD:=.native)
OCAMLBUILDLIBNATIVE=$(WITH_OCAMLBUILD:=lib.native)

OCAMLDOC_OPT=$(WITH_OCAMLDOC:=.opt)

INCLUDES=-I +compiler-libs

TOPLEVEL=toplevel/genprintval.cmo toplevel/toploop.cmo \
  toplevel/trace.cmo toplevel/topdirs.cmo toplevel/topmain.cmo

BYTESTART=driver/main.cmo

OPTSTART=driver/optmain.cmo

TOPLEVELSTART=toplevel/topstart.cmo

NATTOPOBJS=$(UTILS) $(PARSING) $(TYPING) $(COMP) $(ASMCOMP) \
  toplevel/genprintval.cmo toplevel/opttoploop.cmo toplevel/opttopdirs.cmo \
  toplevel/opttopmain.cmo toplevel/opttopstart.cmo

PERVASIVES=$(STDLIB_MODULES) outcometree topdirs toploop

# For users who don't read the INSTALL file
defaultentry:
	@echo "Please refer to the installation instructions in file INSTALL."
	@echo "If you've just unpacked the distribution, something like"
	@echo "	./configure"
	@echo "	make world.opt"
	@echo "	make install"
	@echo "should work.  But see the file INSTALL for more details."

install:
	if test -d $(BINDIR); then : ; else $(MKDIR) $(BINDIR); fi
	if test -d $(LIBDIR); then : ; else $(MKDIR) $(LIBDIR); fi
	if test -d $(STUBLIBDIR); then : ; else $(MKDIR) $(STUBLIBDIR); fi
	if test -d $(COMPLIBDIR); then : ; else $(MKDIR) $(COMPLIBDIR); fi
	if test -d $(MANDIR)/man$(MANEXT); then : ; \
	  else $(MKDIR) $(MANDIR)/man$(MANEXT); fi
	cp VERSION $(LIBDIR)/
	cd $(LIBDIR); rm -f dllbigarray.so dllnums.so dllthreads.so \
	  dllunix.so dllgraphics.so dllstr.so
	cd byterun; $(MAKE) install
	cp ocamlc $(BINDIR)/ocamlc$(EXE)
	cp ocaml $(BINDIR)/ocaml$(EXE)
	cd stdlib; $(MAKE) install
	cp lex/ocamllex $(BINDIR)/ocamllex$(EXE)
	cp yacc/ocamlyacc$(EXE) $(BINDIR)/ocamlyacc$(EXE)
	cp utils/*.cmi parsing/*.cmi typing/*.cmi bytecomp/*.cmi driver/*.cmi \
	   toplevel/*.cmi $(COMPLIBDIR)
	cp compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma \
	   compilerlibs/ocamltoplevel.cma $(BYTESTART) $(TOPLEVELSTART) \
	   $(COMPLIBDIR)
	cp expunge $(LIBDIR)/expunge$(EXE)
	cp toplevel/topdirs.cmi $(LIBDIR)
	cd tools; $(MAKE) install
	-cd man; $(MAKE) install
	for i in $(OTHERLIBRARIES); do \
	  (cd otherlibs/$$i; $(MAKE) install) || exit $$?; \
	done
	if test -n "$(WITH_OCAMLDOC)"; then (cd ocamldoc; $(MAKE) install); else :; fi
	if test -f ocamlopt; then $(MAKE) installopt; else :; fi
	if test -n "$(WITH_OCAMLDEBUG)"; then (cd debugger; $(MAKE) install); \
	   else :; fi
	cp config/Makefile $(LIBDIR)/Makefile.config
	BINDIR=$(BINDIR) LIBDIR=$(LIBDIR) PREFIX=$(PREFIX) \
	  ./build/partial-install.sh

clean:
	$(OCAMLBUILD) -clean

# The bytecode compiler

compilerlibs/ocamlbytecomp.cma: $(BYTECOMP)
	$(CAMLC) -a -o $@ $(BYTECOMP)
partialclean::
	rm -f compilerlibs/ocamlbytecomp.cma

ocamlc: compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma $(BYTESTART)
	$(CAMLC) $(LINKFLAGS) -compat-32 -o ocamlc \
	   compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma $(BYTESTART)
	$(SWITCH_COMPILER) enable COMPILER=CAMLC VARIANT=BYTE
	$(SWITCH_COMPILER) disable COMPILER=CAMLC VARIANT=OPT

partialclean::
	if [ -n "$(ROOTDIR)" ]; then \
	  $(SWITCH_COMPILER) disable COMPILER=CAMLC VARIANT=BYTE ; \
	fi

# The native-code compiler

compilerlibs/ocamloptcomp.cma: $(ASMCOMP)
	$(CAMLC) -a -o $@ $(ASMCOMP)
partialclean::
	rm -f compilerlibs/ocamloptcomp.cma

ocamlopt: compilerlibs/ocamlcommon.cma compilerlibs/ocamloptcomp.cma $(OPTSTART)
	$(CAMLC) $(LINKFLAGS) -o ocamlopt \
	  compilerlibs/ocamlcommon.cma compilerlibs/ocamloptcomp.cma $(OPTSTART)
	$(SWITCH_COMPILER) enable COMPILER=CAMLOPT VARIANT=BYTE
	$(SWITCH_COMPILER) disable COMPILER=CAMLOPT VARIANT=OPT

partialclean::
	rm -f ocamlopt
	if [ -n "$(ROOTDIR)" ]; then \
	  $(SWITCH_COMPILER) disable  COMPILER=CAMLOPT VARIANT=BYTE ; \
	fi

# The toplevel

compilerlibs/ocamltoplevel.cma: $(TOPLEVEL)
	$(CAMLC) -a -o $@ $(TOPLEVEL)
partialclean::
	rm -f compilerlibs/ocamltoplevel.cma

ocaml: compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma \
       compilerlibs/ocamltoplevel.cma $(TOPLEVELSTART) expunge
	$(CAMLC) $(LINKFLAGS) -linkall -o ocaml.tmp \
	  compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma \
	  compilerlibs/ocamltoplevel.cma $(TOPLEVELSTART)
	- $(CAMLRUN) ./expunge ocaml.tmp ocaml $(PERVASIVES)
	rm -f ocaml.tmp

partialclean::
	rm -f ocaml

# The native toplevel

ocamlnat: ocamlopt otherlibs/dynlink/dynlink.cmxa $(NATTOPOBJS:.cmo=.cmx)
	$(CAMLOPT) $(LINKFLAGS) otherlibs/dynlink/dynlink.cmxa -o ocamlnat \
	           $(NATTOPOBJS:.cmo=.cmx) -linkall

toplevel/opttoploop.cmx: otherlibs/dynlink/dynlink.cmxa

otherlibs/dynlink/dynlink.cmxa: otherlibs/dynlink/natdynlink.ml
	cd otherlibs/dynlink && $(MAKE) allopt

# The configuration file

utils/config.ml: utils/config.mlp config/Makefile
	@rm -f utils/config.ml
	sed -e 's|%%LIBDIR%%|$(LIBDIR)|' \
	    -e 's|%%BYTERUN%%|$(BINDIR)/ocamlrun|' \
	    -e 's|%%CCOMPTYPE%%|cc|' \
	    -e 's|%%BYTECC%%|$(BYTECC) $(BYTECCCOMPOPTS) $(SHAREDCCCOMPOPTS)|' \
	    -e 's|%%NATIVECC%%|$(NATIVECC) $(NATIVECCCOMPOPTS)|' \
	    -e 's|%%PACKLD%%|$(PACKLD)|' \
	    -e 's|%%BYTECCLIBS%%|$(BYTECCLIBS)|' \
	    -e 's|%%NATIVECCLIBS%%|$(NATIVECCLIBS)|' \
	    -e 's|%%RANLIBCMD%%|$(RANLIBCMD)|' \
	    -e 's|%%ARCMD%%|$(ARCMD)|' \
	    -e 's|%%CC_PROFILE%%|$(CC_PROFILE)|' \
	    -e 's|%%ARCH%%|$(ARCH)|' \
	    -e 's|%%MODEL%%|$(MODEL)|' \
	    -e 's|%%SYSTEM%%|$(SYSTEM)|' \
	    -e 's|%%EXT_OBJ%%|.o|' \
	    -e 's|%%EXT_ASM%%|.s|' \
	    -e 's|%%EXT_LIB%%|.a|' \
	    -e 's|%%EXT_DLL%%|.so|' \
	    -e 's|%%SYSTHREAD_SUPPORT%%|$(SYSTHREAD_SUPPORT)|' \
	    -e 's|%%ASM%%|$(ASM)|' \
	    -e 's|%%ASM_CFI_SUPPORTED%%|$(ASM_CFI_SUPPORTED)|' \
	    -e 's|%%WITH_FRAME_POINTERS%%|$(WITH_FRAME_POINTERS)|' \
	    -e 's|%%MKDLL%%|$(MKDLL)|' \
	    -e 's|%%MKEXE%%|$(MKEXE)|' \
	    -e 's|%%MKMAINDLL%%|$(MKMAINDLL)|' \
	    -e 's|%%HOST%%|$(HOST)|' \
	    -e 's|%%TARGET%%|$(TARGET)|' \
	    utils/config.mlp > utils/config.ml
	@chmod -w utils/config.ml

partialclean::
	rm -f utils/config.ml

beforedepend:: utils/config.ml

# The parser

parsing/parser.mli parsing/parser.ml: parsing/parser.mly
	$(CAMLYACC) $(YACCFLAGS) parsing/parser.mly

partialclean::
	rm -f parsing/parser.mli parsing/parser.ml parsing/parser.output

beforedepend:: parsing/parser.mli parsing/parser.ml

# The lexer

parsing/lexer.ml: parsing/lexer.mll
	$(CAMLLEX) parsing/lexer.mll

partialclean::
	rm -f parsing/lexer.ml

beforedepend:: parsing/lexer.ml

# Shared parts of the system compiled with the native-code compiler

compilerlibs/ocamlcommon.cmxa: $(COMMON:.cmo=.cmx)
	$(CAMLOPT) -a -o $@ $(COMMON:.cmo=.cmx)
partialclean::
	rm -f compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlcommon.a

# The bytecode compiler compiled with the native-code compiler

compilerlibs/ocamlbytecomp.cmxa: $(BYTECOMP:.cmo=.cmx)
	$(CAMLOPT) -a -o $@ $(BYTECOMP:.cmo=.cmx)
partialclean::
	rm -f compilerlibs/ocamlbytecomp.cmxa compilerlibs/ocamlbytecomp.a

ocamlc.opt: compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlbytecomp.cmxa \
            $(BYTESTART:.cmo=.cmx)
	$(CAMLOPT) $(LINKFLAGS) -ccopt "$(BYTECCLINKOPTS)" -o ocamlc.opt \
	  compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlbytecomp.cmxa \
	  $(BYTESTART:.cmo=.cmx) -cclib "$(BYTECCLIBS)"
	$(SWITCH_COMPILER) enable COMPILER=CAMLC VARIANT=OPT

partialclean::
	rm -f ocamlc.opt
	if [ -n "$(ROOTDIR)" ]; then \
		$(SWITCH_COMPILER) disable COMPILER=CAMLC VARIANT=OPT ; \
	fi

# The native-code compiler compiled with itself

compilerlibs/ocamloptcomp.cmxa: $(ASMCOMP:.cmo=.cmx)
	$(CAMLOPT) -a -o $@ $(ASMCOMP:.cmo=.cmx)
partialclean::
	rm -f compilerlibs/ocamloptcomp.cmxa compilerlibs/ocamloptcomp.a

ocamlopt.opt: compilerlibs/ocamlcommon.cmxa compilerlibs/ocamloptcomp.cmxa \
              $(OPTSTART:.cmo=.cmx)
	$(CAMLOPT) $(LINKFLAGS) -o ocamlopt.opt \
	   compilerlibs/ocamlcommon.cmxa compilerlibs/ocamloptcomp.cmxa \
	   $(OPTSTART:.cmo=.cmx)
	$(SWITCH_COMPILER) enable COMPILER=CAMLOPT VARIANT=OPT

partialclean::
	rm -f ocamlopt.opt
	if [ -n "$(ROOTDIR)" ]; then \
	  $(SWITCH_COMPILER) disable COMPILER=CAMLOPT VARIANT=OPT ; \
	fi

$(COMMON:.cmo=.cmx) $(BYTECOMP:.cmo=.cmx) $(ASMCOMP:.cmo=.cmx): ocamlopt

# The numeric opcodes

bytecomp/opcodes.ml: byterun/instruct.h
	sed -n -e '/^enum/p' -e 's/,//g' -e '/^  /p' byterun/instruct.h | \
	awk -f tools/make-opcodes > bytecomp/opcodes.ml

partialclean::
	rm -f bytecomp/opcodes.ml

beforedepend:: bytecomp/opcodes.ml

# The predefined exceptions and primitives

byterun/primitives:
	cd byterun; $(MAKE) primitives

bytecomp/runtimedef.ml: byterun/primitives byterun/fail.h
	(echo 'let builtin_exceptions = [|'; \
	 sed -n -e 's|.*/\* \("[A-Za-z_]*"\) \*/$$|  \1;|p' byterun/fail.h | \
	 sed -e '$$s/;$$//'; \
	 echo '|]'; \
	 echo 'let builtin_primitives = [|'; \
	 sed -e 's/.*/  "&";/' -e '$$s/;$$//' byterun/primitives; \
	 echo '|]') > bytecomp/runtimedef.ml

partialclean::
	rm -f bytecomp/runtimedef.ml

beforedepend:: bytecomp/runtimedef.ml

# Choose the right machine-dependent files

asmcomp/arch.ml: asmcomp/$(ARCH)/arch.ml
	ln -s $(ARCH)/arch.ml asmcomp/arch.ml

partialclean::
	rm -f asmcomp/arch.ml

beforedepend:: asmcomp/arch.ml

asmcomp/proc.ml: asmcomp/$(ARCH)/proc.ml
	ln -s $(ARCH)/proc.ml asmcomp/proc.ml

partialclean::
	rm -f asmcomp/proc.ml

beforedepend:: asmcomp/proc.ml

asmcomp/selection.ml: asmcomp/$(ARCH)/selection.ml
	ln -s $(ARCH)/selection.ml asmcomp/selection.ml

partialclean::
	rm -f asmcomp/selection.ml

beforedepend:: asmcomp/selection.ml

asmcomp/reload.ml: asmcomp/$(ARCH)/reload.ml
	ln -s $(ARCH)/reload.ml asmcomp/reload.ml

partialclean::
	rm -f asmcomp/reload.ml

beforedepend:: asmcomp/reload.ml

asmcomp/scheduling.ml: asmcomp/$(ARCH)/scheduling.ml
	ln -s $(ARCH)/scheduling.ml asmcomp/scheduling.ml

partialclean::
	rm -f asmcomp/scheduling.ml

beforedepend:: asmcomp/scheduling.ml

# Preprocess the code emitters

asmcomp/emit.ml: asmcomp/$(ARCH)/emit.mlp tools/cvt_emit
	$(CAMLRUN) tools/cvt_emit < asmcomp/$(ARCH)/emit.mlp > asmcomp/emit.ml \
	|| { rm -f asmcomp/emit.ml; exit 2; }

partialclean::
	rm -f asmcomp/emit.ml

beforedepend:: asmcomp/emit.ml

tools/cvt_emit: tools/cvt_emit.mll
	cd tools; $(MAKE) cvt_emit

# The "expunge" utility

expunge: compilerlibs/ocamlcommon.cma compilerlibs/ocamlbytecomp.cma \
         toplevel/expunge.cmo
	$(CAMLC) $(LINKFLAGS) -o expunge compilerlibs/ocamlcommon.cma \
	         compilerlibs/ocamlbytecomp.cma toplevel/expunge.cmo

partialclean::
	rm -f expunge

# The runtime system for the bytecode compiler

runtime:
	cd byterun; $(MAKE) all
	if test -f stdlib/libcamlrun.a; then :; else \
	  ln -s ../byterun/libcamlrun.a stdlib/libcamlrun.a; fi

clean::
	cd byterun; $(MAKE) clean
	rm -f stdlib/libcamlrun.a
	rm -f stdlib/caml

alldepend::
	cd byterun; $(MAKE) depend

# The runtime system for the native-code compiler

runtimeopt: makeruntimeopt
	cp asmrun/libasmrun.a stdlib/libasmrun.a

makeruntimeopt:
	cd asmrun; $(MAKE) all

clean::
	cd asmrun; $(MAKE) clean
	rm -f stdlib/libasmrun.a

alldepend::
	cd asmrun; $(MAKE) depend

# The library

library: ocamlc
	cd stdlib; $(MAKE) all

library-cross:
	cd stdlib; $(MAKE) RUNTIME=../byterun/ocamlrun all

libraryopt:
	cd stdlib; $(MAKE) allopt

partialclean::
	cd stdlib; $(MAKE) clean

alldepend::
	cd stdlib; $(MAKE) depend

# The lexer and parser generators

ocamllex: ocamlyacc ocamlc
	cd lex; $(MAKE) all

ocamllex.opt: ocamlopt
	cd lex; $(MAKE) allopt

partialclean::
	cd lex; $(MAKE) clean

alldepend::
	cd lex; $(MAKE) depend

ocamlyacc:
	cd yacc; $(MAKE) all

clean::
	cd yacc; $(MAKE) clean

# Tools

ocamltools: ocamlc ocamlyacc ocamllex asmcomp/cmx_format.cmi
	cd tools; $(MAKE) all

ocamltoolsopt: ocamlopt
	cd tools; $(MAKE) opt

ocamltoolsopt.opt: ocamlc.opt ocamlyacc ocamllex asmcomp/cmx_format.cmi
	cd tools; $(MAKE) opt.opt

partialclean::
	cd tools; $(MAKE) clean

alldepend::
	cd tools; $(MAKE) depend

# OCamldoc

ocamldoc: ocamlc ocamlyacc ocamllex otherlibraries
	cd ocamldoc && $(MAKE) all

ocamldoc.opt: ocamlc.opt ocamlyacc ocamllex
	cd ocamldoc && $(MAKE) opt.opt

partialclean::
	cd ocamldoc && $(MAKE) clean

alldepend::
	cd ocamldoc && $(MAKE) depend

# The extra libraries

otherlibraries: ocamltools
	for i in $(OTHERLIBRARIES); do \
	  (cd otherlibs/$$i; $(MAKE) RUNTIME=$(RUNTIME) all) || exit $$?; \
	done

otherlibrariesopt:
	for i in $(OTHERLIBRARIES); do \
	  (cd otherlibs/$$i; $(MAKE) allopt) || exit $$?; \
	done

partialclean::
	for i in $(OTHERLIBRARIES); do \
	  (cd otherlibs/$$i && $(MAKE) partialclean); \
	done

clean::
	for i in $(OTHERLIBRARIES); do (cd otherlibs/$$i && $(MAKE) clean); done

alldepend::
	for i in $(OTHERLIBRARIES); do (cd otherlibs/$$i; $(MAKE) depend); done

# The replay debugger

ocamldebugger: ocamlc ocamlyacc ocamllex otherlibraries
	cd debugger; $(MAKE) all

partialclean::
	cd debugger; $(MAKE) clean

alldepend::
	cd debugger; $(MAKE) depend

# Camlp4

camlp4out: ocamlc ocamlbuild.byte
	./build/camlp4-byte-only.sh

camlp4opt: ocamlopt otherlibrariesopt ocamlbuild-mixed-boot ocamlbuild.native
	./build/camlp4-native-only.sh

partialclean::
	rm -rf _build

# Make MacOS X package

package-macosx:
	sudo rm -rf package-macosx/root
	$(MAKE) PREFIX="`pwd`"/package-macosx/root install
	tools/make-package-macosx
	sudo rm -rf package-macosx/root

clean::
	rm -rf package-macosx/*.pkg package-macosx/*.dmg

# Default rules

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(CAMLC) $(COMPFLAGS) -c $<

.mli.cmi:
	$(CAMLC) $(COMPFLAGS) -c $<

.ml.cmx:
	$(CAMLOPT) $(COMPFLAGS) -c $<

partialclean::
	for d in utils parsing typing bytecomp asmcomp driver toplevel tools; \
	  do rm -f $$d/*.cm[iox] $$d/*.annot $$d/*.[so] $$d/*~; done
	rm -f *~

depend: beforedepend
	(for d in utils parsing typing bytecomp asmcomp driver toplevel; \
	 do $(CAMLDEP) $(DEPFLAGS) $$d/*.mli $$d/*.ml; \
	 done) > .depend

alldepend:: depend

distclean:
	./build/distclean.sh
	rm -f ocaml testsuite/_log

.PHONY: all backup bootstrap camlp4opt camlp4out checkstack clean
.PHONY: partialclean beforedepend alldepend cleanboot coldstart
.PHONY: compare core coreall
.PHONY: coreboot defaultentry depend distclean install installopt
.PHONY: library library-cross libraryopt
.PHONY: ocamlbuild.byte ocamlbuild.native ocamldebugger ocamldoc
.PHONY: ocamldoc.opt ocamllex ocamllex.opt ocamltools ocamltoolsopt
.PHONY: ocamltoolsopt.opt ocamlyacc opt-core opt opt.opt otherlibraries
.PHONY: otherlibrariesopt package-macosx promote promote-cross
.PHONY: restore runtime runtimeopt makeruntimeopt world world.opt

include .depend
