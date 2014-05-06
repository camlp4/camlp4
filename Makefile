OB := ocamlbuild -classic-display -no-ocamlfind

LIB ?= /usr/local/lib/

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

.PHONY: install-META
install-META:
	mkdir -p ${LIB}/camlp4/
	cp -f camlp4/META ${LIB}/camlp4/

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
