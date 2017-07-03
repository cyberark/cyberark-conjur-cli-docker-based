#!/bin/bash -e

for i in $(seq 10); do
	curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null && break
	echo -n "." 1>&2
	sleep 2
done

possum account create cucumber
