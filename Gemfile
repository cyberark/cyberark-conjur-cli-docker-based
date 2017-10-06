source 'https://rubygems.org'

#ruby=ruby-2.4.1
#ruby-gemset=conjur-cli

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'activesupport', '~> 4.2'

gem 'conjur-api', '>= 4.30.0', '~> 4'

group :test, :development do
  gem 'pry'                     # Don't be tempted to change this to pry-byebug until we drop support for 1.9
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'conjur-debify', '~> 1.0', require: false
end
