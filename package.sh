#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

# Make sure Gemfile.lock exists
bundle

debify package \
	--dockerfile ci/Dockerfile.fpm \
	cli \
	-- \
	--depends ruby2.0

debify publish 4.6 cli
