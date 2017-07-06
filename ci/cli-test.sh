#!/bin/bash -ex

bundle install

${@-bundle exec rake jenkins}
