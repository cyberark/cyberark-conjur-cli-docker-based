source 'https://rubygems.org'

#ruby=ruby-2.2.5
#ruby-gemset=conjur-cli

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'activesupport', '~> 4.2'

gem 'conjur-api', '>= 4.29.0', git: 'https://github.com/conjurinc/api-ruby.git', branch: 'feature/pagination'
gem 'semantic', '>= 1.4.1', git: 'https://github.com/jlindsey/semantic.git'

group :development do
  gem 'pry-byebug'
end

group :test, :development do
  gem 'ruby-prof'
  gem 'conjur-debify', '~> 1.0', require: false
end
