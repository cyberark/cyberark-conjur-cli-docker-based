# Conjur

*NOTE*: This is work-in-progress, for a future (as yet unreleased) version of Conjur.
_It will not work with Conjur 4._

Command-line interface to Conjur 5.

A complete reference guide is available at [developer.conjur.net](http://developer.conjur.net/reference).

## Quick start

    $ docker run -it conjurinc/cli5
    $ conjur -v
    conjur version 6.0.0beta.1

## Docker images

[![Docker Build Status](https://img.shields.io/docker/build/conjurinc/cli5.svg)](https://hub.docker.com/r/conjurinc/cli5/)

Images for development/experimental use are automatically built [on docker hub](https://hub.docker.com/r/conjurinc/cli5/).
These are based off [Dockerfile.standalone](Dockerfile.standalone) and can be rebuilt with:

    docker build . -f Dockerfile.standalone -t conjurinc/cli5

Note these images are not subject to any QA at the moment and so should never be used in production, especially without specific image id pin.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
