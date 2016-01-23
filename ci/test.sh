#!/bin/bash

conjur_cid="$1"

cat << TEST | docker exec -i $conjur_cid bash
#!/bin/bash -ex

cd /src/cli

unset CONJUR_AUTHN_LOGIN

bundle exec rake jenkins || true
bundle exec cucumber -r acceptance-features/support \
	-r acceptance-features/step_definitions \
	-f pretty \
	-f junit --out acceptance-features/reports \
	acceptance-features || true
TEST
