#!/bin/bash

searchstring='DEPRECATED'

function bundleexec {
  bundle exec "$@" 2> /dev/null
}

echo "Planned deprecations for Conjur CLI"
echo "-----"

echo "group"
bundleexec conjur group | grep "$searchstring"
echo "group members"
bundleexec conjur group members | grep "$searchstring"

echo "hostfactory"
bundleexec conjur hostfactory | grep "$searchstring"

echo "host"
bundleexec conjur host | grep "$searchstring"

echo "layer"
bundleexec conjur layer | grep "$searchstring"
echo "layer hosts"
bundleexec conjur layer hosts | grep "$searchstring"

echo "resource"
bundleexec conjur resource | grep "$searchstring"

echo "role"
bundleexec conjur role | grep "$searchstring"

echo "user"
bundleexec conjur user | grep "$searchstring"

echo "variable"
bundleexec conjur variable | grep "$searchstring"
