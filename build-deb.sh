#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

debify clean

docker build -t conjur-cli-fpm -f Dockerfile.fpm .

mkdir -p tmp/deb

docker run -v $PWD/tmp/deb:/share --rm conjur-cli-fpm

debify test -t 4.6-stable cli ci/test.sh
