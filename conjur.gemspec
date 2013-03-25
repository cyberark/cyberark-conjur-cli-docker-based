# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki", "Kevin Gilpin"]
  gem.email         = ["divided.mind@gmail.com", "kevin.gilpin@inscitiv.com",]
  gem.summary       = %q{Conjur command line interface}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur2"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::VERSION
  
  gem.add_dependency 'conjur-api'
  gem.add_dependency 'gli'
  gem.add_dependency 'highline'
  gem.add_dependency 'netrc'
  
  gem.add_runtime_dependency 'cas_rest_client'
  
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
end
