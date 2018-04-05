#!/bin/bash
set -ex

export COMPOSE_PROJECT_NAME=clirubydev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --no-deps --rm conjur data-key generate > data_key
	docker-compose run --no-deps --rm conjurctl role retrieve-key cucumber:user:admin
fi

export CONJUR_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec conjur conjurctl wait

apikey=$(docker-compose exec conjur \
  conjurctl role retrieve-key cucumber:user:admin)

set +x
echo ''
echo ''
echo '=============== LOGIN WITH THESE CREDENTIALS ==============='
echo ''
echo 'username: admin'
echo "api key : ${apikey}"
echo ''
echo '============================================================'
echo ''
echo ''
set -x

docker-compose exec cli bash
