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
