#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

debify package \
	--dockerfile ci/Dockerfile.fpm \
	cli \
	-- \
	--depends ruby2.0

