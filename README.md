# Conjur

Command-line interface to Conjur.

A complete reference guide is available at [developer.conjur.net](http://developer.conjur.net/reference).

Note that this `v4` branch is for Conjur 4.x. Use `master` for Conjur 5.x and later.

## Installation

Add this line to your application's Gemfile:

    gem 'conjur-cli', require: 'conjur/cli'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-cli

### Using Docker

This software is included in the standalone `cyberark/conjur-cli:4` Docker
image. Docker containers are designed to be ephemeral, which means they don't
store state after the container exits.

You can start an ephemeral session with the Conjur CLI software like so:

```sh-session
$ docker run --rm -it cyberark/conjur-cli:4
root@b27a95721e7d:~# 
```

Any initialization you do or files you create in that session will be discarded
(permanently lost) when you exit the shell. Changes that you make to the Conjur
server will remain.

You can also use a folder on your filesystem to persist the data that the Conjur
CLI uses to connect. For example:

```sh-session
$ mkdir mydata
$ chmod 700 mydata
$ docker run --rm -it -v $(PWD)/mydata:/root cyberark/conjur-cli:4 init -h https://conjur.myorg.com
SHA1 Fingerprint=16:C8:F8:AC:7B:57:BD:5B:58:B4:13:27:22:8E:3F:A2:12:01:DB:68

Please verify this certificate on the appliance using command:
                openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem

Trust this certificate (yes/no): yes
Wrote certificate to /root/conjur-conjur.pem
Wrote configuration to /root/.conjurrc
$ ls -lA mydata
total 8
drwxr-xr-x 2 you staff   64 Mar 28 19:30 .cache
-rw-r--r-- 1 you staff  128 Mar 28 19:30 .conjurrc
-rw-r--r-- 1 you staff 2665 Mar 28 19:30 conjur-conjur.pem
$ docker run --rm -it -v $(PWD)/mydata:/root cyberark/conjur-cli:4 authn login -u your-user-name
Please enter your password (it will not be echoed): 
Logged in
$ ls -lA mydata
total 12
drwxr-xr-x 2 you staff   64 Mar 28 19:26 .cache
-rw-r--r-- 1 you staff  128 Mar 28 19:20 .conjurrc
-rw------- 1 you staff  143 Mar 28 19:27 .netrc
-rw-r--r-- 1 you staff 2665 Mar 28 19:20 conjur-conjur.pem
$ 
```

*Security notice:* the file `.netrc`, created or updated by `conjur authn
login`, contains a user identity credential that can be used to access the
Conjur API. You should remove it after use or otherwise secure it like you would
another netrc file.

### Bash completion

To enable bash completions, run this command:

    $ conjur shellinit >> ~/.bashrc

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
