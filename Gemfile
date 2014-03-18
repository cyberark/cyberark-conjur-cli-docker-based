source 'https://rubygems.org'

# Specify your gem's dependencies in conjur.gemspec
gemspec

gem 'conjur-api', git: 'https://github.com/inscitiv/api-ruby.git', branch: 'update-audit-commands'
group :test, :development do
  gem 'pry'
end

group :development do
  gem 'conjur-asset-environment-api'
  gem 'conjur-asset-key-pair-api'
  gem 'conjur-asset-layer-api'
  gem 'conjur-asset-ui-api', github: 'conjurinc/conjur-asset-ui', branch: 'new-audit' 
end
