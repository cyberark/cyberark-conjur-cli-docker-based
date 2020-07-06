# conjur-cli

Command-line interface for Conjur.

*NOTE*: Conjur v4 users should use the `v5.x.x` release path. Conjur CLI `v6.0.0` only supports Conjur v5 and newer.

A complete reference guide is available at [conjur.org](https://www.conjur.org).

## Table of Contents
- [Getting Started](#getting-started)
    - [Quick Start](#quick-start)
    - [Using This Project With Conjur OSS](#Using-conjur-cli-with-Conjur-OSS)
- [Using Docker](#using-docker)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Getting Started 

### Quick start

```sh-session
$ gem install conjur-cli

$ conjur -v
conjur version 6.0.0
```

### Using conjur-cli with Conjur OSS 

Are you using this project with [Conjur OSS](https://github.com/cyberark/conjur)? Then we 
**strongly** recommend choosing the version of this project to use from the latest [Conjur OSS 
suite release](https://docs.conjur.org/Latest/en/Content/Overview/Conjur-OSS-Suite-Overview.html). 
Conjur maintainers perform additional testing on the suite release versions to ensure 
compatibility. When possible, upgrade your Conjur version to match the 
[latest suite release](https://docs.conjur.org/Latest/en/Content/ReleaseNotes/ConjurOSS-suite-RN.htm); 
when using integrations, choose the latest suite release that matches your Conjur version. For any 
questions, please contact us on [Discourse](https://discuss.cyberarkcommons.org/c/conjur/5).

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

## Usage

```
NAME
    conjur - Command-line toolkit for managing roles, resources and privileges

SYNOPSIS
    conjur [global options] command [command options] [arguments...]

GLOBAL OPTIONS
    --help    - Show this message
    --version - Display the program version
```

### Commands

| Command                            | Description                                       |
| ---------------------------------- | ------------------------------------------------- |
| [authn](#conjur-authn)             | - Login and logout                                |
| [check](#conjur-check)             | - Check for a privilege on a resource             |
| [env](#conjur-env)                 | - Use values of Conjur variables in local context |
| [host](#conjur-host)               | - Manage hosts                                    |
| [hostfactory](#conjur-hostfactory) | - Manage host factories                           |
| [init](#conjur-init)               | - Initialize the Conjur configuration             |
| [ldap-sync](#conjur-ldap-sync)     | - LDAP sync management commands                   |
| [list](#conjur-list)               | - List objects                                    |
| [plugin](#conjur-plugin)           | - Manage plugins                                  |
| [policy](#conjur-policy)           | - Manage policies                                 |
| [pubkeys](#conjur-pubkeys)         | - Public keys service operations                  |
| [resource](#conjur-resource)       | - Manage resources                                |
| [role](#conjur-role)               | - Manage roles                                    |
| [show](#conjur-show)               | - Show an object                                  |
| [user](#conjur-user)               | - Manage users                                    |
| [variable](#conjur-variable)       | - Manage variables                                |

#### `conjur authn`

```
NAME
   authn       - Login and logout
SYNOPSIS
    conjur [global options] authn authenticate [-H|--header] [-f filename|--filename filename]
    conjur [global options] authn login [-p password|--password password] [-u username|--username username] login-name
    conjur [global options] authn logout
    conjur [global options] authn whoami
COMMANDS
    authenticate - Obtains an authentication token using the current logged-in
                   user
    login        - Logs in and caches credentials to netrc.
    logout       - Logs out
    whoami       - Prints out the current logged in username
```

#### `conjur check`

```
NAME
   check       - Check for a user’s privilege on a resource
SYNOPSIS
   conjur check [object] [privilege] [user]
PRIVILEGES
   read, write, execute
```

#### `conjur env`

```
NAME
    env         - Use values of Conjur variables in local context
SYNOPSIS
    conjur [global options] env check [--policy arg] [--yaml arg] [-c FILE]
    conjur [global options] env help
    conjur [global options] env run [--policy arg] [--yaml arg] [-c FILE] -- command [arg1, arg2 ...]
    conjur [global options] env template [--policy arg] [--yaml arg] [-c FILE] template.erb

COMMANDS
    check    - Check availability of Conjur variables
    help     - Print description of environment configuration format
    run      - Execute external command with environment variables populated
               from Conjur
    template - Render ERB template with variables obtained from Conjur

root@e1bfc649b68d:/# conjur env help

Environment configuration (either stored in file referred by -c option or provided inline with --yaml option) should be a YAML document describing one-level Hash.
Keys of the hash are 'local names', used to refer to variable values in convenient manner.  (See help for env:run and env:template for more details about how they are interpreted).

Values of the hash may take one of the following forms: a) string b) string preceeded with !var tag c) string preceeded with !tmp tag.

a) Plain string is just associated with local name without any calls to Conjur.

b) String preceeded by !var tag is interpreted as an ID of the Conjur variable, which value should be obtained and associated with appropriate local name.

c) String preceeded by !tmp tag is interpreted as an ID of the Conjur variable, which value should be stored in temporary file, which location should in turn be associated with appropriate local name.

Example of environment configuration: 

{ local_variable_1: 'literal value', local_variable_2: !var id/of/Conjur/Variable , local_variable_3: !tmp id/of/another/Conjur/variable }
```

#### `conjur host`

```
NAME
    host - Manage hosts

SYNOPSIS
    conjur [global options] host layers HOST
    conjur [global options] host rotate_api_key [--host arg|-h arg]

COMMANDS
    layers         - List the layers to which the host belongs
    rotate_api_key - Rotate a host's API key
```

#### `conjur hostfactory`

```
NAME
    hostfactory - Manage host factories

SYNOPSIS
    conjur [global options] hostfactory hosts
    conjur [global options] hostfactory tokens

COMMANDS
    hosts  - Operations on hosts
    tokens - Operations on tokens
```

#### `conjur init`

```
NAME
   init – Initialize the Conjur configuration
SYNOPSIS
   conjur [global options] init [-u URL of Conjur service] [-a account name]
```

#### `conjur ldap-sync`

```
NAME
    ldap-sync - LDAP sync management commands

SYNOPSIS
    conjur [global options] ldap-sync policy

COMMANDS
    policy - Manage the policy used to sync Conjur and the LDAP server
```

#### `conjur list`

```
Lists conjur objects
```

#### `conjur plugin`

```
NAME
    plugin - Manage plugins

SYNOPSIS
    conjur [global options] plugin install [-v version|--version version] PLUGIN
    conjur [global options] plugin list
    conjur [global options] plugin show PLUGIN
    conjur [global options] plugin uninstall PLUGIN

COMMANDS
    install   - Install a plugin
    list      - List installed plugins
    show      - Show a plugin's details
    uninstall - Uninstall a plugin
```

#### `conjur policy`

```
NAME
    policy - Manage policies

SYNOPSIS
    conjur [global options] policy load [--delete] [--replace] POLICY FILENAME

COMMANDS
    load - Load a policy
--delete – deletes a policy
--replace – replaces a policy
```

#### `conjur pubkeys`

```
NAME
   pubkeys - Public keys service operations
SYNOPSIS
   conjur [global options] pubkeys [USER]
```

#### `conjur resource`

```
NAME
    resource - Manage resources

SYNOPSIS
    conjur [global options] resource exists RESOURCE
    conjur [global options] resource permitted_roles RESOURCE PRIVILEGE

COMMANDS
    exists          - Determines whether a resource exists
    permitted_roles - List roles with a specified privilege on the resource
```

#### `conjur role`

```
NAME
    role - Manage roles

SYNOPSIS
    conjur [global options] role exists [--json] ROLE
    conjur [global options] role members [-V|--verbose] ROLE
    conjur [global options] role memberships [-s|--system] ROLE

COMMANDS
    exists      - Determines whether a role exists
    members     - Lists all direct members of the role. The membership list is
                  not recursively expanded.
    memberships - Lists role memberships. The role membership list is
                  recursively expanded.
```

#### `conjur show`

```
NAME
   show        - Show an object
SYNOPSIS
   conjur show [object]
```

#### `conjur user`

```
NAME
    user - Manage users

SYNOPSIS
    conjur [global options] user rotate_api_key [--user arg|-u arg]
    conjur [global options] user update_password [-p arg|--password arg]

COMMANDS
    rotate_api_key  - Rotate a user's API key
    update_password - Update the password of the logged-in user
```

#### `conjur variable`

```
NAME
    variable - Manage variables

SYNOPSIS
    conjur [global options] variable value [-v arg|--version arg] VARIABLE
    conjur [global options] variable values

COMMANDS
    value  - Get a value
    values - Access variable values
```

## Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get started and descriptions of our development workflows, please see our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md

## License

This repository is licensed under Apache License 2.0 - see [`LICENSE`](LICENSE) for more details.
