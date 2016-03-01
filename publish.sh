#!/bin/bash -e

distribution=$1
component=${2:-`echo $GIT_BRANCH | sed 's/^origin\///' | tr '/' '.'`}

if [ "$distribution" == "" ]; then
  echo Distribution is required
  exit 1
fi
if [ "$component" == "" ]; then
  echo Component is required
  exit 1
fi

if [ "$ART_USERNAME" == "" -o "$ART_PASSWORD" == "" ]; then
  echo Usage: summon -f ci/secrets/publish.yml ./publish.sh
  exit 1
fi

docker build -t conjur-cli-publish -f Dockerfile.publish .

for package in *.deb; do
  echo Publishing "$package"
  docker run \
    --rm \
    -v $PWD/tmp/deb:/src \
    conjur-cli-publish \
    art \
    upload \
    --url https://conjurinc.artifactoryonline.com/conjurinc \
    --user $ART_USERNAME \
    --password $ART_PASSWORD \
    --deb "$distribution"/"$component"/amd64 \
    $package \
    debian-public
done
