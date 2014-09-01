case $XARCH in
i386)
  uname -a
  git clone git://github.com/ocaml/ocaml
  cd ocaml
  ./configure
  make world.opt
  sudo make install
  cd ..
  rm -rf ocaml
  ./configure && make && sudo make install
  ;;
*)
  echo unknown arch
  exit 1
  ;;
esac
