source 'https://rubygems.org'

#ruby=ruby-2.2.5
#ruby-gemset=conjur-cli

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'activesupport', '~> 4.2'

gem 'conjur-api', '>= 4.29.0', git: 'https://github.com/conjurinc/api-ruby.git', branch: 'master'
gem 'semantic', '>= 1.4.1', git: 'https://github.com/jlindsey/semantic.git'

group :test, :development do
  gem 'pry'                     # Don't be tempted to change this to pry-byebug until we drop support for 1.9
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'conjur-debify', '~> 1.0'
end
