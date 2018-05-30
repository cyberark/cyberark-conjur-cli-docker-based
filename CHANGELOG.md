# 6.1.1

* No longer displaying error stack traces by default when an exception occurs duing CLI
  initialization (e.g when trying to open a missing conjur certificate file). Stack traces
  can be enabled for all errors in the CLI by setting the environment variable `GLI_DEBUG=true`.

# [6.1.0](https://github.com/cyberark/conjur-cli/releases/tag/v6.1.0)

* Pin dependency 'conjur-api' to '~> 5.1'. This update adds authn-local support to the API. [conjur-api PR #131](https://github.com/cyberark/conjur-api-ruby/pull/131)

# [6.0.1](https://github.com/cyberark/conjur-cli/releases/tag/v6.0.1)

* Pushes to `cyberark/conjur-cli:5` on DockerHub when tests pass
* Use SNI when fetching certificate with `conjur init`.
* Correctly specify dependency versions in gemspec.
* Allow ActiveSupport v5 as a dependency.

# [6.0.0](https://github.com/cyberark/conjur-cli/releases/tag/v6.0.0)

* Provides compatibility with [cyberark/conjur](https://github.com/cyberark/conjur), Conjur 5 CE.
* License changed to Apache 2.0.
* **Codebase forked: for changes to the 5.x (API [v4][v4-branch]) series, see
  [CHANGELOG in `v4` branch][v4-changelog]**

[v4-branch]: https://github.com/cyberark/conjur-cli/tree/v4
[v4-changelog]: https://github.com/cyberark/conjur-cli/blob/v4/CHANGELOG.md
