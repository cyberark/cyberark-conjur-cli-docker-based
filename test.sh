#!/bin/bash -ex

: ${RUBY_VERSION=3.0}

# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION=$(cut -d '-' -f 2 <<< $RUBY_VERSION)

main() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running, run it first and retry"
    exit 1
  fi

  # set up the containers to run in their own namespace
  COMPOSE_PROJECT_NAME="$(basename "$PWD")_$(openssl rand -hex 3)"
  export COMPOSE_PROJECT_NAME

  build

  start_conjur

  run_tests
}

# internal functions

build() {
  # we can get rid of this once we upgrade to docker 17.06+
  sed "s/\${RUBY_VERSION}/$RUBY_VERSION/" Dockerfile > Dockerfile.$RUBY_VERSION

  docker-compose build --pull
}

start_conjur() {
  docker-compose pull pg conjur

  env CONJUR_DATA_KEY="$(docker-compose run -T --no-deps conjur data-key generate)" \
    docker-compose up -d conjur
  trap "docker-compose down" EXIT

  docker-compose run test ci/wait_for_server.sh
}

run_tests() {
  env CONJUR_AUTHN_API_KEY=$(docker-compose exec -T conjur rails r "print Credentials['cucumber:user:admin'].api_key") \
    docker-compose run test "$@"
}

main
