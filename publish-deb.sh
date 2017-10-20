#!/bin/bash -e

distribution=$1
component=${2:-`echo $BRANCH_NAME | sed 's/^origin\///' | tr '/' '.'`}

exec summon -f ci/secrets/publish.yml ./ci/publish.sh $distribution $component
