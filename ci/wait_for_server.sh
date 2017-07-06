#!/bin/bash -ex

for i in $(seq 10); do
	curl -o /dev/null -fs -X OPTIONS http://possum > /dev/null && break
    echo .
	sleep 2
done

# So we fail if the server isn't up yet:
curl -o /dev/null -fs -X OPTIONS http://possum > /dev/null
