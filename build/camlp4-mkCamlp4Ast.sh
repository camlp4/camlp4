#!/bin/sh

############################################################################
#                                                                          #
#                                   OCaml                                  #
#                                                                          #
#          Nicolas Pouillard, projet Gallium, INRIA Rocquencourt           #
#                                                                          #
#  Copyright  2010   Institut National de Recherche  en  Informatique et   #
#  en Automatique.  All rights reserved.  This file is distributed under   #
#  the terms of the GNU Library General Public License, with the special   #
#  exception on linking described in LICENSE at the top of the OCaml       #
#  source tree.                                                            #
#                                                                          #
############################################################################

set -e
if [ ! -e camlp4/META.in ] ; then
  echo "script $0 invoked from the wrong location"
  exit 1
fi

. ./config.sh
export PATH=$BINDIR:$PATH

CAMLP4AST=camlp4/Camlp4/Struct/Camlp4Ast.ml
BOOTP4AST=camlp4/boot/Camlp4Ast.ml

[ -f "$BOOTP4AST" ] && mv "$BOOTP4AST" "$BOOTP4AST.old"
rm -f "_build/$BOOTP4AST"
rm -f "_build/$CAMLP4AST"

cmd() {
    echo $@
    $@
}

cmd camlp4boot \
    -printer r \
    -filter map \
    -filter fold \
    -filter meta \
    -filter trash \
    -impl camlp4/Camlp4/Struct/Camlp4Ast.mlast \
    -o camlp4/boot/Camlp4Ast.ml
