# 4.22.0

* New 'plugin' subcommand to manage CLI plugins
* Configure SSL certificate from Conjur.configuration
* Print the error message if there's a problem loading a plugin

# 4.21.1

* Configure trust to the new certificate in `conjur init`, before attempting to contact the Conjur server

# 4.21.0

* Use user cache dir for mimetype cache
* Retrieve the whole certificate chain on conjur init

# 4.20.1

* Improve the error reporting

# 4.20.0

* GID manipulation commands

# 4.19.0

* Add command `conjur role graph` for batch retrieval of role relationships

# 4.18.5

* Bump conjur-api version to mime-types problem

# 4.18.4

* Revert "Find (and store) credentials by only a hostname as the machine in netrc"

# 4.18.3

* Use the latest conjur-ssh cookbook version for conjurize

# 4.18.2

* Require a recent version of netrc
* Complain if netrc is world readable
* Find (and store) credentials by only a hostname as the machine in netrc
* Make the command start up faster by lazy loading some gems
* `authn whoami` will notice if the user is logged in via env vars
* `conjurize` default conjur-ssh cookbook updated to 1.2.2

# 4.18.0

* New `conjurize` command
* Deprecate the `host enroll` command
* `variable create` command now takes an optional value for the variable after the variable id
* Configure "permissive" netrc to allow the `conjur` Unix group to read the `.netrc` or `conjur.identity` file.

# 4.17.0

* Support --policy parameter in `conjur env`
* Bugfix: failures on 'variable retire'
* Raise a better error in case of missing config

# 4.16.0

* Add 'bootstrap' CLI command
* Raise a better error if conjur env encounters a variable with no value

# 4.15.0

* Migration to rspec 3
* Commands to retire(decommission) variable, host, user, group
* Bugfix (in some situations `conjur init` logged config file location incorrectly)
