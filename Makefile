OB := ocamlbuild -classic-display -use-ocamlfind -plugin-tag "package(camlp-streams)"
DESTDIR=

-include config.sh

OB += $(OB_FLAGS)

.PHONY: default
default: byte

.PHONY: byte
byte:
	$(OB) `sh ./build/camlp4-byte-only.sh`

.PHONY: native
native:
	$(OB) `sh ./build/camlp4-native-only.sh`

.PHONY: all
all: byte native

.PHONY: install
install:
	env DESTDIR=$(DESTDIR) sh ./build/install.sh

.PHONY: install-META
install-META: camlp4/META
	mkdir -p $(DESTDIR)${PKGDIR}/camlp4/
	cp -f camlp4/META $(DESTDIR)${PKGDIR}/camlp4/

camlp4/META: camlp4/META.in
	sed -e s/@@VERSION@@/${version}/g $? > $@

.PHONY: bootstrap
bootstrap:
	sh ./build/camlp4-bootstrap.sh

.PHONY: Camlp4Ast
Camlp4Ast:
	sh ./build/camlp4-mkCamlp4Ast.sh

.PHONY: clean
clean:
	rm -rf _build

.PHONY: distclean
distclean:
	rm -rf _build myocamlbuild_config.ml Makefile.config
