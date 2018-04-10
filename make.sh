#!/bin/sh

camlp4orf -v 2> /dev/null || { cat install && exit 1; }

version="`camlp4 -version`"
sed -e "s/@@VERSION@@/$version/g" META.in > META

