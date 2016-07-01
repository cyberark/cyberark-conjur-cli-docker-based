source 'https://rubygems.org'

#ruby=ruby-2.2.4
#ruby-gemset=conjur-cli

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'conjur-api', '>= 4.26', git: 'https://github.com/conjurinc/api-ruby.git', branch: 'master'
gem 'semantic', '>= 1.4.1', git: 'https://github.com/jlindsey/semantic.git'

group :test, :development do
  gem 'pry'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'conjur-debify', '~> 1.0'
end
