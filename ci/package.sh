#!/bin/bash -ex

gem install -N rake
mkdir /tmp/gems
rake build
gem install --no-ri --no-rdoc --install-dir /tmp/gems pkg/*.gem
find /tmp/gems/cache -name '*.gem' | xargs -rn1 fpm -d ruby2.0 --prefix $(gem environment gemdir) -s gem -t deb

rm -rf /share/*
rsync -a *.deb /share

