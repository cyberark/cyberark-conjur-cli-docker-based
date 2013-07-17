# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki", "Kevin Gilpin"]
  gem.email         = ["divided.mind@gmail.com", "kgilpin@conjur.net",]
  gem.summary       = %q{Conjur command line interface}
  gem.homepage      = "https://github.com/inscitiv/cli-ruby"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-cli"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::VERSION
  
  gem.add_dependency 'conjur-api', '~> 2.4'
  gem.add_dependency 'gli'
  gem.add_dependency 'highline'
  gem.add_dependency 'netrc'
  gem.add_dependency 'methadone'
  
  gem.add_runtime_dependency 'cas_rest_client'
  
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'aruba'
  gem.add_development_dependency 'ci_reporter', '~> 1.8'
  gem.add_development_dependency 'rake', '~> 10.0'
end
