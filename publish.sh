#!/usr/bin/env bash
# ! /bin/bash -e

# conjurinc/publish-rubygem -> conjurinc/release-tools/bin/publish-rubygem
#docker pull registry.tld/conjurinc/release-tools/bin/publish-rubygem

#summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
#  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
#  registry.tld/conjurinc/release-tools/bin/publish-rubygem-container-entrpoint.sh conjur-cli

#publish-rubygem-container-entrpoint.sh

#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <project>"
  exit 1
fi

project="${1}"

if [ ! -f "${project}.gemspec" ]; then
  echo "Cannot find ${project}.gemspec"
  echo "Usage: $0 <project>"
  exit 1
fi

echo "Updating package list..."
apt-get update > /dev/null 2>&1
echo "Installing dependencies..."
apt-get install -y git > /dev/null 2>&1

git config --global --add safe.directory "$(pwd)"

echo "Building gem..."

gem build "${project}.gemspec"

echo "Publishing gem..."
# write API key to credentials file
mkdir -p /root/.gem
cat > /root/.gem/credentials <<EOF
---
:rubygems_api_key: $RUBYGEMS_API_KEY
EOF
chmod 0600 /root/.gem/credentials

spec_name=$(grep spec.name "${project}.gemspec" | awk -F"=" '{print $2}' | xargs)

# Some gems use gem rather than spec
if [ -z "${spec_name}" ]; then
  spec_name=$(grep gem.name "${project}.gemspec" | awk -F"=" '{print $2}' | xargs)
fi

gem push "${spec_name}"-*.gem