#!/bin/bash -e

docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd

docker pull registry.tld/conjurinc/publish-rubygem

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
  registry.tld/conjurinc/publish-rubygem conjur-cli

docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd
