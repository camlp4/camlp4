OB := ocamlbuild -classic-display -no-ocamlfind
DESTDIR=

-include config.sh

OB += $(OB_FLAGS)

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
	env DESTDIR=$(DESTDIR) ./build/install.sh

.PHONY: install-META
install-META: camlp4/META
	mkdir -p $(DESTDIR)${PKGDIR}/camlp4/
	cp -f camlp4/META $(DESTDIR)${PKGDIR}/camlp4/

camlp4/META: camlp4/META.in
	sed -e s/@@VERSION@@/${version}/g $? > $@

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
