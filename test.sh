#!/bin/bash -ex

: ${IMAGE_NAME=cli-ruby:2.2.4}

docker run -i --rm \
  -v $PWD:/src \
  ${IMAGE_NAME} ci/cli-test.sh "$@"

