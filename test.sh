#!/bin/bash -ex

set -a
POSSUM_IMAGE=registry.tld/possum:0.1.0-stable

: ${RUBY_VERSION=2.2}
sed "s/\${RUBY_VERSION}/$RUBY_VERSION/" Dockerfile > Dockerfile.$RUBY_VERSION
docker-compose build test

function finish {
  docker-compose down
}
trap finish EXIT

POSSUM_DATA_KEY="$(docker-compose run --no-deps possum data-key generate)"

docker-compose up -d possum

docker-compose run test ci/wait_for_server.sh

CONJUR_AUTHN_API_KEY=$(docker-compose exec possum rails r "print Credentials['cucumber:user:admin'].api_key")

docker-compose run test "$@"

