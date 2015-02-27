#!/bin/sh

############################################################################
#                                                                          #
#                                   OCaml                                  #
#                                                                          #
#          Nicolas Pouillard, projet Gallium, INRIA Rocquencourt           #
#                                                                          #
#  Copyright  2008   Institut National de Recherche  en  Informatique et   #
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
. build/camlp4-targets.sh
set -x

echo $CAMLP4_NATIVE
