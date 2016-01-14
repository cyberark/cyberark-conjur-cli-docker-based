#!/bin/bash -e

# Constants
RUBY_VERSION_DEFAULT="2.1.5"

# Arguments
RUBY_VERSION=${1-${RUBY_VERSION_DEFAULT}}

# Script

# Clones 'Dockerfile' and updates the Ruby version in FROM, returning the cloned file's path
function dockerfile_path {
    echo "Setting Ruby version as ${RUBY_VERSION}" >&2
    cp "Dockerfile" "Dockerfile.${RUBY_VERSION}"
    sed -i "s/${RUBY_VERSION_DEFAULT}/${RUBY_VERSION}/g" Dockerfile.${RUBY_VERSION}

    echo "Dockerfile.${RUBY_VERSION}"
}

rm -f Gemfile.lock # Needed for bundle to work right

IMAGE_NAME="cli-ruby:${RUBY_VERSION}" # The tag is the version of Ruby tested against

docker build -t ${IMAGE_NAME} -f $(dockerfile_path) .

docker run --rm \
-v $PWD:/src \
${IMAGE_NAME} \
bash -c '''
bundle update
bundle exec rake jenkins
bundle exec rake build
'''

if [ "$RUBY_VERSION" == "$RUBY_VERSION_DEFAULT" ]; then
	./package.sh
	./publish.sh
fi
