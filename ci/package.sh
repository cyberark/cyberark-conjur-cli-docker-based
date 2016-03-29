#!/bin/bash -ex

mkdir -p /tmp/gems
mkdir -p /tmp/src

rm -f /share/*

rake build

gem install --no-ri --no-rdoc --install-dir /tmp/gems pkg/*.gem

ITERATION=$(date +%s)

find /tmp/gems/cache -name '*.gem' | xargs -rn1 \
fpm --prefix $(gem environment gemdir) --iteration $ITERATION -s gem -t deb

cp -a *.deb /share
