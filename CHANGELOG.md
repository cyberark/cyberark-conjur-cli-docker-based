# 4.29.0

* Add `cidr` commands to `user`, `host`, and `hostfactory token`
* Move `audit send` and `host factory` commands from plugins into the core CLI
* Add `variable expire` and `variable expirations` subcommands. Variable expirations is available in version 4.6 of the Conjur server.
* Add `--json` option to `conjurize` to print the Conjur configuration and host identity as a JSON file
* Require `--layer` argument to `hostfactory create`, ensure that the owner is an admin of the layer.
	
# 4.28.2
* `--collection` is now optional (with no default) for both `conjur script execute` and `conjur policy load`.

# 4.28.1
* Add `--collection` option for `conjur script execute`. Scripts are now portable across environments, like policies.

# 4.28.0
* Add `conjur policy retire` to allow retiring a policy.
* Fix `--as-group` and `--as-role` options for `conjur policy load`. Either can now be used to specify ownership of the policy.
* Fix `--follow` option for `conjur audit`.
* Remove support for per-project `.conjurrc` files.

# 4.27.0

* New commands `elevate` and `reveal` for execution of privileged commands on Conjur 4.5+.

# 4.26.0

* New implementation of bash completions.

# 4.25.2
* Fixes a conflict with RVM: Sets `GEM_HOME` and `GEM_PATH to nil.

# 4.25.1

* Remove spurious line written to stdout during user creation.
* Fix up-front permission checking in `conjur bootstrap` so that it will run on a fresh server.

# 4.25.0

* A record can be retired to a specific role, in addition to the default behavior of retiring to the `attic` user.
* Variable can be created with the id only, without becoming interactive.
* Run `conjur variable create -i -a` to create interactively with annotations.
* Interactive annotation can be performed on bare resources with `conjur resource annotate -i`.
* Don't require 'admin' user to bootstrap, prompt to create a new security admin during bootstrap.
* Check if user privileges are sufficient before running `retire`.
* Don't revoke a user's access to a record in the middle of retire, because doing so leads to 403 errors later on.
* Interactive mode of user, group and pubkey creation.

# 4.24.0

* Interactive mode for variable creation.

# 4.23.0

* Don't check if netrc is world-readable on Windows, since the answer is not reliable.
* Use new [conjur](https://supermarket.chef.io/cookbooks/conjur) cookbook for conjurize.
* Fix faulty initialization of plugins list, if it's nil, in the .conjurrc.
* Log DSL commands to stderr, even if CONJURAPI_LOG is not explicitly configured.
* In policy DSL, allow creation of records without an explicit `id`. In this case, the current scope is used as the `id`.

# 4.22.0

* New 'plugin' subcommand to manage CLI plugins.
* Configure SSL certificate from Conjur.configuration.
* Print the error message if there's a problem loading a plugin.

# 4.21.1

* Configure trust to the new certificate in `conjur init`, before attempting to contact the Conjur server.

# 4.21.0

* Use user cache dir for mimetype cache.
* Retrieve the whole certificate chain on conjur init.

# 4.20.1

* Improve the error reporting.

# 4.20.0

* GID manipulation commands.

# 4.19.0

* Add command `conjur role graph` for batch retrieval of role relationships.

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
