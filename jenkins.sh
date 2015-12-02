#!/bin/bash -e

bundle update
bundle exec rake jenkins
bundle exec rake build
