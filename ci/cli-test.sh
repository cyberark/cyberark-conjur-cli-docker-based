#!/bin/bash -ex

bundle update

# Run rake build if the tests pass, but exit 0 if they fail (so the build we marked unstable)
bundle exec ${@-rake jenkins} && bundle exec rake build || true



