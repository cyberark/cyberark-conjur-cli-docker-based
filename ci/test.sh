#!/bin/bash

conjur_cid="$1"

docker exec $conjur_cid bash -c "conjur-dev-service rake jenkins || true"
