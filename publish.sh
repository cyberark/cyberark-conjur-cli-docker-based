#!/bin/bash -exu

export DEBUG=true 
export GLI_DEBUG=true 

DISTRIBUTION=$1
COMPONENT=$(echo $GIT_BRANCH | sed 's/^origin\\///' | tr '/' '.')

debify publish --component $COMPONENT $DISTRIBUTION cli
