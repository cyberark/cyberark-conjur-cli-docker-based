# conjur-cli

Command-line interface for Conjur.

*NOTE*: Conjur v4 users should use the `v5.x.x` release path. Conjur CLI `v6.0.0` only supports Conjur v5 and newer.

A complete reference guide is available at [conjur.org](https://www.conjur.org).

## Quick start

```sh-session
$ gem install conjur-cli

$ conjur -v
conjur version 6.0.0
```

## Using Docker
[![Docker Build Status](https://img.shields.io/docker/build/conjurinc/cli5.svg)](https://hub.docker.com/r/conjurinc/cli5/)
This software is included in the standalone cyberark/conjur-cli:5 Docker image. Docker containers are designed to be ephemeral, which means they don't store state after the container exits.

You can start an ephemeral session with the Conjur CLI software like so:
```sh-session 
$ docker run --rm -it cyberark/conjur-cli:5
root@b27a95721e7d:~# 
```

Any initialization you do or files you create in that session will be discarded (permanently lost) when you exit the shell. Changes that you make to the Conjur server will remain.

You can also use a folder on your filesystem to persist the data that the Conjur CLI uses to connect. For example:
```sh-session
$ mkdir mydata
$ chmod 700 mydata
$ docker run --rm -it -v $(PWD)/mydata:/root cyberark/conjur-cli:5 init -u https://eval.conjur.org

SHA1 Fingerprint=E6:F7:AC:E3:3A:54:83:4F:D0:06:9B:49:45:C3:85:58:ED:34:4C:4C

Please verify this certificate on the appliance using command:
              openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem

Trust this certificate (yes/no): yes
Enter your organization account name: your.email@yourorg.net
Wrote certificate to /root/conjur-your.email@yourorg.net.pem
Wrote configuration to /root/.conjurrc
$ ls -lA mydata
total 16
drwxr-xr-x  2 you  staff    68 Mar 29 14:16 .cache
-rw-r--r--  1 you  staff   136 Mar 29 14:16 .conjurrc
-rw-r--r--  1 you  staff  3444 Mar 29 14:16 conjur-your.email@yourorg.net.pem
$ docker run --rm -it -v $(PWD)/mydata:/root cyberark/conjur-cli:5 authn login -u admin 
Please enter admin's password (it will not be echoed): 
Logged in
$ ls -lA mydata
total 24
drwxr-xr-x  2 you  staff    68 Mar 29 14:16 .cache
-rw-r--r--  1 you  staff   136 Mar 29 14:16 .conjurrc
-rw-------  1 you  staff   119 Mar 29 14:19 .netrc
-rw-r--r--  1 you  staff  3444 Mar 29 14:16 conjur-your.email@yourorg.net.pem
```
*Security notice:* the file `.netrc`, created or updated by `conjur authn login`, contains a user identity credential that can be used to access the Conjur API. You should remove it after use or otherwise secure it like you would another netrc file.

## Development

Create a sandbox environment in Docker using the `./dev` folder:

```sh-session
$ cd dev
dev $ ./start.sh
```

This will drop you into a bash shell in a container called `cli`.

The sandbox also includes a Postgres container and Conjur server container. The
environment is already setup to connect the CLI to the server:

* **CONJUR_APPLIANCE_URL** `http://conjur`
* **CONJUR_ACCOUNT** `cucumber`

To login to conjur, type the following and you'll be prompted for a password:

```sh-session
root@2b5f618dfdcb:/# conjur authn login admin
Please enter admin's password (it will not be echoed):
```

The required password is the API key at the end of the output from the
`start.sh` script.  It looks like this:

```
=============== LOGIN WITH THESE CREDENTIALS ===============

username: admin
api key : 9j113d35wag023rq7tnv201rsym1jg4pev1t1nb4419767ms1cnq00n

============================================================
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

## License

Copyright 2016-2017 CyberArk

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this software except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
