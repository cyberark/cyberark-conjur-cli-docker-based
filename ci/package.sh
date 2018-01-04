#!/bin/bash -ex

mkdir -p /tmp/gems
mkdir -p /tmp/src

rm -f /share/*

rake build

gem install --no-ri --no-rdoc --install-dir /tmp/gems pkg/*.gem

find /tmp/gems/cache -name '*.gem' | xargs -rn1 \
fpm --prefix $(gem environment gemdir) -s gem -t deb

cp -a *.deb /share
