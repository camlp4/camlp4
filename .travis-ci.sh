case $XARCH in
i386)
  uname -a
  git clone -b 4.02 git://github.com/ocaml/ocaml
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
