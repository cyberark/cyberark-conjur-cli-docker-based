source 'https://rubygems.org'

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'conjur-api', git: 'https://github.com/conjurinc/api-ruby.git', branch: 'master'

group :test, :development do
  gem 'pry'
end

group :development do
  gem 'conjur-asset-environment-api', git: 'git@github.com:inscitiv/conjur-asset-environment', branch: 'master'
  gem 'conjur-asset-key-pair-api', git: 'git@github.com:conjurinc/conjur-asset-key-pair', branch: 'master'
  gem 'conjur-asset-layer-api', git: 'git@github.com:conjurinc/conjur-asset-layer', branch: 'master'
  gem 'conjur-asset-ui-api', git: 'git@github.com:conjurinc/conjur-asset-ui', branch: 'master'
end
