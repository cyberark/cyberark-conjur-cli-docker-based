#!/bin/bash -e

set -o pipefail

cd /share && dpkg-scanpackages . /dev/null | gzip -c9 > Packages.gz

echo deb file:///share / >> /etc/apt/sources.list

apt-get update && apt-get install -y --force-yes rubygem-conjur-cli

conjur help
