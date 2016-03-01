#!/bin/bash -ex

mkdir -p /tmp/gems

rake build
version=$(ruby -Ilib -rconjur/version -e "puts Conjur::VERSION")

gem install --no-ri --no-rdoc --install-dir /tmp/gems pkg/*.gem

find /tmp/gems/cache -name '*.gem' | xargs -rn1 fpm -d ruby2.0 --prefix $(gem environment gemdir) -s gem -t deb

cp -a *.deb /share

rm -rf /src
mkdir /src
mkdir -p /src/opt/conjur/cli
cd /src

fpm -a all \
  -s dir \
  -t deb \
  -n conjur-cli \
  -v $version \
  -C . \
  -d "rubygem-conjur-cli = $version" \
  --maintainer "Conjur Inc." \
  --vendor "Conjur Inc." \
  --url "https://www.conjur.net"

cp -a *.deb /share
