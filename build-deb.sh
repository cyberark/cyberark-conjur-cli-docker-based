#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

# Make sure Gemfile.lock exists
gem install -N bundler
bundle

debify clean

debify package \
	--dockerfile ci/Dockerfile.fpm \
	cli \
	-- \
	--depends ruby2.0

debify package \
	--dockerfile ci/Dockerfile-dev.fpm \
	cli-dev \
	-- \
	--depends ruby2.0

debify test -t 4.6-stable cli ci/test.sh
