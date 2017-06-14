This text file is intended to describe in human terms the actions that are
needed to set this project up which cannot be easily specified in a
machine-readable way due to lack of required tools (or the lack of my
knowledge of them).

The intent is for this document to reflect the current state. The timestamp of
when the state was changed/checked should be included with the description
to emphasize this, even though in principle git log should also have this information.

For pull requests, when the requester is unable to perform the change of state
or state should only be changed after merging, a note to that effect should be
included instead. The onus is then on whoever is merging to actually apply the
changes and update the timestamp in this document.

# Dockerhub builds

The dockerhub repository should be created as a public automatic build
repository, linked to the github repo for automatic build on push.

To accomplish that, follow the guide at https://docs.docker.com/docker-hub/github/

## Settings

Dockerhub repo: https://hub.docker.com/r/conjurinc/cli5/
Github repo: https://github.com/conjurinc/cli-ruby

### [Automated build settings](https://hub.docker.com/r/conjurinc/cli5/~/settings/automated-builds/):

- Automatically build on pushes: yes.
- Branch-tag mapping (type ‖ name ‖ dockerfile location ‖ docker tag name)
  - branch ‖ standalone-dockerized ‖ /Dockerfile.standalone ‖ latest
  - branch ‖ possum ‖ /Dockerfile.standalone ‖ latest

Note: the first branch-tag mapping can be removed after merging: it is only
useful for this feature branch.

[Configuration true as of 2017-06-14T20:41+00:00.]
