#!/bin/bash
set -e

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

rvm use --create 1.9.3@conjur-cli
rake build
rvm use --create 1.9.3@conjur-cli-ci
gem install pkg/conjur-cli-4.2.0.gem --no-rdoc --no-ri
