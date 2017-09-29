#!/bin/bash -ex

: ${RUBY_VERSION=2.2.5}

# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION=$(cut -d '-' -f 2 <<< $RUBY_VERSION)

main() {
  build

  start_possum

  run_tests
}

# internal functions

build() {
  # we can get rid of this once we upgrade to docker 17.06+
  sed "s/\${RUBY_VERSION}/$RUBY_VERSION/" Dockerfile > Dockerfile.$RUBY_VERSION

  docker-compose build --pull
}

start_possum() {
  docker-compose pull pg possum

  env CONJUR_DATA_KEY="$(docker-compose run -T --no-deps possum data-key generate)" \
    docker-compose up -d possum
  trap "docker-compose down" EXIT

  docker-compose run test ci/wait_for_server.sh
}

run_tests() {
  env CONJUR_AUTHN_API_KEY=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key") \
    docker-compose run test "$@"
}

main
