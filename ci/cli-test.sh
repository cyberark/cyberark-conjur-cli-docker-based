#!/bin/bash -ex

# This can run with mounted source directory which is used in different Ruby versions.
# Since library support is different for different versions, clear out the lock to
# make sure full gem resolution runs each time.
rm -f Gemfile.lock
bundle install

# If we got passed arguments, run that as the test command. Otherwise, run the full suite of tests.
exec ${@-bundle exec rake jenkins}
