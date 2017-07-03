#!/bin/bash -ex

RUBY_VERSION=${1-2.2.4}


dockerfile=Dockerfile.${RUBY_VERSION}
test_dockerfile=Dockerfile.test.${RUBY_VERSION}

sed "s/@@RUBY_VERSION@@/${RUBY_VERSION}/g" Dockerfile > $dockerfile
sed "s/@@RUBY_VERSION@@/${RUBY_VERSION}/g" Dockerfile.test > $test_dockerfile

docker build -t cli-ruby:${RUBY_VERSION} -f $dockerfile .
docker build -t cli-ruby-test:${RUBY_VERSION} -f $test_dockerfile .
