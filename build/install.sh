#!/bin/sh

#########################################################################
#                                                                       #
#                                 OCaml                                 #
#                                                                       #
#       Nicolas Pouillard, projet Gallium, INRIA Rocquencourt           #
#                                                                       #
#   Copyright 2007 Institut National de Recherche en Informatique et    #
#   en Automatique.  All rights reserved.  This file is distributed     #
#   under the terms of the Q Public License version 1.0.                #
#                                                                       #
#########################################################################

set -e

cd `dirname $0`/..

# Save the following environment variables before sourcing config.sh
# since it will overwrite them and the user might have set them to
# emulate $(DESTDIR) which is unfortunately not supported.
SAVED_BINDIR="${BINDIR}"
SAVED_LIBDIR="${LIBDIR}"

. ./config.sh

BINDIR="${SAVED_BINDIR:-${BINDIR}}"
LIBDIR="${SAVED_LIBDIR:-${LIBDIR}}"

not_installed=$PWD/_build/not_installed

rm -f "$not_installed"
touch "$not_installed"

wontinstall() {
  echo "$1" >> "$not_installed"
  echo "  don't install $1"
}

installbin() {
  if [ -f "$1" ]; then
    echo "  install binary $2"
    cp -f "$1" "$2"
    [ -x "$2" ] || chmod +x "$2"
  else
    wontinstall "$1"
  fi
}

installbestbin() {
  if [ -f "$1" ]; then
    echo "  install binary $3 (with `basename $1`)"
    cp -f "$1" "$3"
  else
    if [ -f "$2" ]; then
      echo "  install binary $3 (with `basename $2`)"
      cp -f "$2" "$3"
    else
      echo "None of $1, $2 exists"
      exit 3
    fi
  fi
  [ -x "$3" ] || chmod +x "$3"
}

installlib() {
  if [ -f "$1" ]; then
    dest="$2/`basename $1`"
    echo "  install library $dest"
    cp -f "$1" "$2"
    if [ "$ranlib" != "" ]; then
      "$ranlib" "$dest"
    fi
  else
    wontinstall "$1"
  fi
}

installdir() {
  args=""
  while [ $# -gt 1 ]; do
    if [ -f "$1" ]; then
      args="$args $1"
    else
      wontinstall "$1"
    fi
    shift
  done
  last="$1"
  for file in $args; do
    echo "  install $last/`basename $file`"
    cp -f "$file" "$last"
  done
}

installlibdir() {
  args=""
  while [ $# -gt 1 ]; do
    args="$args $1"
    shift
  done
  last="$1"
  for file in $args; do
    installlib "$file" "$last"
  done
}

mkdir -p $BINDIR
mkdir -p $LIBDIR/camlp4

cd _build

echo "Installing camlp4..."
installbin camlp4/camlp4prof.byte$EXE $BINDIR/camlp4prof$EXE
installbin camlp4/mkcamlp4.byte$EXE $BINDIR/mkcamlp4$EXE
installbin camlp4/camlp4.byte$EXE $BINDIR/camlp4$EXE
installbin camlp4/camlp4boot.byte$EXE $BINDIR/camlp4boot$EXE
installbin camlp4/camlp4o.byte$EXE $BINDIR/camlp4o$EXE
installbin camlp4/camlp4of.byte$EXE $BINDIR/camlp4of$EXE
installbin camlp4/camlp4oof.byte$EXE $BINDIR/camlp4oof$EXE
installbin camlp4/camlp4orf.byte$EXE $BINDIR/camlp4orf$EXE
installbin camlp4/camlp4r.byte$EXE $BINDIR/camlp4r$EXE
installbin camlp4/camlp4rf.byte$EXE $BINDIR/camlp4rf$EXE
installbin camlp4/camlp4o.native$EXE $BINDIR/camlp4o.opt$EXE
installbin camlp4/camlp4of.native$EXE $BINDIR/camlp4of.opt$EXE
installbin camlp4/camlp4oof.native$EXE $BINDIR/camlp4oof.opt$EXE
installbin camlp4/camlp4orf.native$EXE $BINDIR/camlp4orf.opt$EXE
installbin camlp4/camlp4r.native$EXE $BINDIR/camlp4r.opt$EXE
installbin camlp4/camlp4rf.native$EXE $BINDIR/camlp4rf.opt$EXE

cd camlp4
ocamlfind install camlp4 camlp4/META \
  camlp4lib.cma camlp4lib.cmxa Camlp4.cmi \
  camlp4fulllib.cma camlp4fulllib.cmxa \
  camlp4o.cma camlp4of.cma camlp4oof.cma \
  camlp4orf.cma camlp4r.cma camlp4rf.cma \
  Camlp4Bin.cm[iox] Camlp4Bin$O Camlp4Top.cm[io] \
  config/Camlp4_config.cmi camlp4prof.cm[iox] camlp4prof$O
CAMLP4DIR=`ocamlfind query camlp4`
installlibdir camlp4lib$A camlp4fulllib$A $CAMLP4DIR
for dir in Camlp4Parsers Camlp4Printers Camlp4Filters Camlp4Top; do
  echo "Installing $dir..."
  mkdir -p $CAMLP4DIR/$dir
  installdir     \
    $dir/*.cm*   \
    $dir/*$O    \
    $CAMLP4DIR/$dir
done
cd ..
