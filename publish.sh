#!/bin/bash -e

# conjurinc/publish-rubygem -> conjurinc/release-tools
docker pull registry.tld/conjurinc/release-tools

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
  registry.tld/conjurinc/release-tools conjur-cli
