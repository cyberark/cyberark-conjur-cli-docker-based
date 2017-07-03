#!/bin/bash -ex

function finish {
	docker rm -f $pg_cid
	docker rm -f $server_cid
}
trap finish EXIT

possum_tag=0.1.0-stable
possum_image=registry.tld/possum:$possum_tag

export POSSUM_DATA_KEY="$(docker run --rm $possum_image data-key generate)"

pg_cid=$(docker run -d postgres:9.3)

server_cid=$(docker run -d \
	--link $pg_cid:pg \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	$possum_image server)

set -o pipefail
admin_api_key=( $(cat ci/setup-account.sh | docker exec -i $server_cid /bin/bash | tail -1) )

mkdir -p spec/reports features/reports

docker run \
	-i \
	--rm \
	--link $pg_cid:pg \
	--link $server_cid:possum \
    -v $PWD/spec/reports:/src/spec/reports \
    -v $PWD/features/reports:/src/features/reports \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	-e CONJUR_APPLIANCE_URL=http://possum \
	-e CONJUR_ACCOUNT=cucumber \
    -e CONJUR_AUTHN_LOGIN=admin \
    -e CONJUR_AUTHN_API_KEY=${admin_api_key[3]} \
  cli-ruby-test:$RUBY_VERSION ci/cli-test.sh "$@"

