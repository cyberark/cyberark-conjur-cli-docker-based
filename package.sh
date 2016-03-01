#!/bin/bash -ex

mkdir -p /tmp/gems

rake build
gem install --no-ri --no-rdoc --install-dir /tmp/gems pkg/*.gem

find /tmp/gems/cache -name '*.gem' | xargs -rn1 fpm -d ruby2.0 --prefix $(gem environment gemdir) -s gem -t deb --gem-package-name-prefix conjur-gem

cp -a *.deb /share
