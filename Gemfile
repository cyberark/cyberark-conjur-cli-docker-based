source 'https://rubygems.org'

#ruby=ruby-2.1.5
#ruby-gemset=conjur-cli

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'conjur-api', git: 'https://github.com/conjurinc/api-ruby.git', branch: 'master'

group :test, :development do
  gem 'pry'
  gem 'pry-doc'
  gem 'ruby-prof'
end

group :debify do
  gem 'conjur-debify', git: 'https://github.com/conjurinc/debify.git', branch: 'master'
end
