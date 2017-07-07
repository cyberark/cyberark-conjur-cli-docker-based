#!/bin/bash -ex

bundle install

# If we got passed arguments, run that as the test command. Otherwise, run the full suite of tests.
${@-bundle exec rake jenkins}
