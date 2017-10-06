#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

if [[ "$(id -un)" == "jenkins" ]]; then
  docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd
fi  

docker build -t conjur-cli-fpm -f Dockerfile.fpm .
docker build -t conjur-cli-validate-packaging -f Dockerfile.validate-packaging .

mkdir -p tmp/deb

docker run -v $PWD/tmp/deb:/share --rm conjur-cli-fpm

# Test that the install succeeds
docker run --rm -v $PWD/tmp/deb:/share conjur-cli-validate-packaging
