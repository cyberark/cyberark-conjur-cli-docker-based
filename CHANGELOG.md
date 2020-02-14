# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [6.2.1] - 2019-05-22
### Added
- Pin to xdg gem v2.2.3 due to a [crashing CLI](https://github.com/cyberark/conjur-cli/issues/243).

## 6.2.0 - 2018-06-22
### Added
- Add `ldap-sync` subcommand.

## 6.1.1 - 0000-00-00
### Added
- No longer displaying error stack traces by default when an exception occurs duing CLI initialization (e.g when trying to open a missing conjur certificate file). Stack traces can be enabled for all errors in the CLI by setting the environment variable `GLI_DEBUG=true`.

## [6.1.0] - 2018-04-09
### Added
- Pin dependency 'conjur-api' to '~> 5.1'. This update adds authn-local support to the API. [conjur-api PR #131](https://github.com/cyberark/conjur-api-ruby/pull/131)

## [6.0.1] - 2018-04-09
### Added
- Pushes to `cyberark/conjur-cli:5` on DockerHub when tests pass
- Use SNI when fetching certificate with `conjur init`.
- Correctly specify dependency versions in gemspec.
- Allow ActiveSupport v5 as a dependency.

## [6.0.0] - 2017-10-13
### Added
- Provides compatibility with [cyberark/conjur](https://github.com/cyberark/conjur), Conjur 5 CE.
- License changed to Apache 2.0.
- **Codebase forked: for changes to the 5.x (API [v4](https://github.com/cyberark/conjur-cli/tree/v4)) series, see
  [CHANGELOG in `v4` branch][v4-changelog](https://github.com/cyberark/conjur-cli/blob/v4/CHANGELOG.md)**

[Unreleased]: https://github.com/cyberark/conjur-cli/compare/v6.2.1...HEAD
[6.2.1]: https://github.com/cyberark/conjur-cli/compare/v6.2.0...v6.2.1
[6.1.0]: https://github.com/cyberark/conjur-cli/compare/v6.0.1...v6.1.0
[6.0.1]: https://github.com/cyberark/conjur-cli/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/cyberark/conjur-cli/compare/v5.6.6...v6.0.0
