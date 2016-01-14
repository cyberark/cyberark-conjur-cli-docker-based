#!/bin/bash -ex

export DEBUG=true 
export GLI_DEBUG=true 

debify package \
	cli \
	-- \
	--depends ruby2.0

