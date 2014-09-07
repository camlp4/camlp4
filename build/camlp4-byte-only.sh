#!/bin/sh

#########################################################################
#                                                                       #
#                                 OCaml                                 #
#                                                                       #
#         Nicolas Pouillard, projet Gallium, INRIA Rocquencourt         #
#                                                                       #
#   Copyright 2008 Institut National de Recherche en Informatique et    #
#   en Automatique.  All rights reserved.  This file is distributed     #
#   under the terms of the Q Public License version 1.0.                #
#                                                                       #
#########################################################################

set -e
if [ ! -e camlp4/META.in ] ; then
  echo "script $0 invoked from the wrong location"
  exit 1
fi

. ./config.sh
. build/camlp4-targets.sh
set -x

echo $CAMLP4_BYTE
