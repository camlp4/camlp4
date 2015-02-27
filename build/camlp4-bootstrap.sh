#!/bin/sh

############################################################################
#                                                                          #
#                                   OCaml                                  #
#                                                                          #
#          Nicolas Pouillard, projet Gallium, INRIA Rocquencourt           #
#                                                                          #
#  Copyright  2007   Institut National de Recherche  en  Informatique et   #
#  en Automatique.  All rights reserved.  This file is distributed under   #
#  the terms of the GNU Library General Public License, with the special   #
#  exception on linking described in LICENSE at the top of the OCaml       #
#  source tree.                                                            #
#                                                                          #
############################################################################

# README: to bootstrap camlp4 have a look at build/camlp4-bootstrap-recipe.txt

set -e
if [ ! -e camlp4/META.in ] ; then
  echo "script $0 invoked from the wrong location"
  exit 1
fi

. ./config.sh
export PATH=$BINDIR:$PATH

TMPTARGETS="\
  camlp4/boot/Lexer.ml"

TARGETS="\
  camlp4/boot/Camlp4Ast.ml \
  camlp4/boot/Camlp4.ml \
  camlp4/boot/camlp4boot.ml"

for target in $TARGETS camlp4/boot/Camlp4Ast.ml; do
  [ -f "$target" ] && mv "$target" "$target.old"
  rm -f "_build/$target"
done

cmd() {
    echo $@
    $@
}

cmd camlp4o _build/camlp4/Camlp4/Struct/Lexer.ml -printer r -o camlp4/boot/Lexer.ml
cmd camlp4boot \
    -printer r \
    -filter map \
    -filter fold \
    -filter meta \
    -filter trash \
    -impl camlp4/Camlp4/Struct/Camlp4Ast.mlast \
    -o camlp4/boot/Camlp4Ast.ml
for t in Camlp4 camlp4boot; do
    cmd camlp4boot -impl camlp4/boot/$t.ml4 -printer o -D OPT -o camlp4/boot/$t.ml
done
rm -f camlp4/boot/Lexer.ml

for t in $TARGETS; do
  echo promote $t
  if cmp $t $t.old; then
    echo "fixpoint for $t"
  else
    echo "$t is different, you should rebootstrap it by cleaning, building and call this script"
  fi
done
