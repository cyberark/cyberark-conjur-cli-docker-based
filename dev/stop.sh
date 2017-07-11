#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=clirubydev

docker-compose stop
docker-compose rm -f
