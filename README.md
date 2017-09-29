# Conjur

*NOTE*: This is work-in-progress, for a future (as yet unreleased) version of Conjur.
_It will not work with Conjur 4._

Command-line interface to Conjur 5.

A complete reference guide is available at [developer.conjur.net](http://developer.conjur.net/reference).

## Quick start

```sh-session
$ docker run -it -v $PWD:/work conjurinc/cli5
root@2b5f618dfdcb:/# conjur -v
conjur version 6.0.0.pre.beta.2
```

## Docker images

[![Docker Build Status](https://img.shields.io/docker/build/conjurinc/cli5.svg)](https://hub.docker.com/r/conjurinc/cli5/)

Images for development/experimental use are automatically built [on docker hub](https://hub.docker.com/r/conjurinc/cli5/).
These are based off [Dockerfile.standalone](Dockerfile.standalone) and can be rebuilt with:

    docker build . -f Dockerfile.standalone -t conjurinc/cli5

Note these images are not subject to any QA at the moment and so should never be used in production, especially without specific image id pin.

## Development

Create a sandbox environment in Docker using the `./dev` folder:

```sh-session
$ cd dev
dev $ ./start.sh
```

This will drop you into a bash shell in a container called `cli`. The sandbox also includes a Postgres container and Conjur server container. The environment is already setup to connect the CLI to the server:

* **CONJUR_APPLIANCE_URL** `http://conjur`
* **CONJUR_ACCOUNT** `cucumber`

You can obtain the API key for the role `cucumber:user:admin` from the Docker logs of the Conjur container. Use it to login:

```sh-session
root@2b5f618dfdcb:/# conjur authn login admin
Please enter admin's password (it will not be echoed):
Logged in
```

At this point, you can use any CLI command you like.

### Running Cucumber

To install dev packages, run `bundle` from within the container:

```sh-session
root@2b5f618dfdcb:/# cd /usr/src/cli-ruby/
root@2b5f618dfdcb:/usr/src/cli-ruby# bundle
```

Then you can run the cucumber tests:

```sh-session
root@2b5f618dfdcb:/usr/src/cli-ruby# cucumber
...
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
