case $XARCH in
i386)
  uname -a

  git clone git://github.com/ocaml/ocaml -b 4.06 --depth 1
  cd ocaml
  ./configure
  make world.opt
  sudo make install
  cd ..
  rm -rf ocaml

  git clone git://github.com/ocaml/ocamlbuild
  cd ocamlbuild
  make
  sudo make install
  cd ..
  rm -rf ocamlbuild

  ./configure && make && sudo make install
  ;;
*)
  echo unknown arch
  exit 1
  ;;
esac
