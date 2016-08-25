# 5.3.0

* Add `jobs` subcommands for `ldap-sync`.
* Add `--detach` switch to `now` subcommand.

# 5.2.5

* Fix behavior of `conjur env` when [policy plugin](https://github.com/conjurinc/conjur-asset-policy) is installed.

# 5.2.4

* Fix behavior of `conjur env`, when detecting variables vs literals

# 5.2.3

* Disable prompts in bootstrap when there's no tty
* Bump api-ruby, fixes 404 core bug

# 5.2.1

* Fix handling of `ldap-sync` dry-run argument.

# 5.2.0

* Add `ldap-sync` management commands (requires Conjur 4.7 or later).
* Use `CONJUR_AUTHN_TOKEN` as the Conjur access token, if it's available in the environment.
* `conjurize` will ignore `conjur` cookbook releases that don't have an associated tarball.
* Pass `--recipe-url` argument to Chef, which is now required.

# 5.1.2

* Fix problem finding config files for plugin installation.

# 5.1.1

* Global CLI plugin config is now stored in `/opt/conjur/etc/plugins.yml`.

# 5.0.0

* **Breaking change** Ruby Policy DSL is now deprecated in favor of 
[new YML policy markup](https://developer.conjur.net/reference/policy-markup.html).
The existing `policy` subcommand has been moved to the `rubydsl` subcommand. 
The new `policy` command operates on YML policies.
* Created a new non-Omnibus Debian packaging of the Ruby gems.

# 4.30.1

* Fix the `conjur-api` gem dependency version

# 4.30.0

* Implementation of `conjur bootstrap` is moved to the API gem, and made extensible.
* Added new steps to `conjur bootstrap`, including the creation of service identities, and giving `elevate` and `reveal` to the `security_admin` group.
* `hostfactory create` verifies that the current role is able to admin the host factory group; otherwise, host factory creation will fail.

# 4.29.0
* Add `conjur host rotate_api_key` command.
* Add `conjur version` (as well as `conjur server version`) command to show server version info.
* Add `conjur server health` and `conjur server info` to display server health and info.
* Add `conjur version` (as well as `conjur server version`) command to show server version info.
* Add `conjur server health` and `conjur server info` to display server health and info.
* Check server version compatibility if exception occurs and command has configured minimum version
* Add `conjur layer retire` to allow retiring a layer.
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
