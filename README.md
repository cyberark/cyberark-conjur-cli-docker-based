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

## Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get started and descriptions of our development workflows, please see our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md

## License

This repository is licensed under Apache License 2.0 - see [`LICENSE`](LICENSE) for more details.
