# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur/version', __FILE__)
require "English"

Gem::Specification.new do |gem|
  gem.authors       = ["Conjur Maintainers"]
  gem.email         = ["conj_maintainers@cyberark.com",]
  gem.summary       = %q{Conjur command line interface}
  gem.homepage      = "https://github.com/cyberark/conjur-cli"
  gem.license       = 'Apache 2.0'

  gem.files         = (`git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
                                     .select { |x| x !~ /^Dockerfile/ }
                      ) + Dir["build_number"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-cli"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::VERSION

  # Filter out development only executables
  gem.executables -= %w{parse-changelog.sh}

  gem.add_dependency 'activesupport', '>= 4.2'
  gem.add_dependency 'conjur-api', '~> 5.3'
  gem.add_dependency 'deep_merge', '~> 1.0'
  gem.add_dependency 'gli', '>=2.8.0'
  gem.add_dependency 'highline', '~> 2.0'
  gem.add_dependency 'netrc', '~> 0.10'
  gem.add_dependency 'table_print', '~> 1.5'
  gem.add_dependency 'xdg', '= 2.2.3'

  gem.add_development_dependency 'addressable'
  gem.add_development_dependency 'aruba', '~> 0.12'
  gem.add_development_dependency 'ci_reporter_rspec', '~> 1.0'
  gem.add_development_dependency 'cucumber-api'
  gem.add_development_dependency 'io-grab', '~> 0.0'
  gem.add_development_dependency 'json_spec'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rake', '~> 12.3.3'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'simplecov', '~> 0.17', '< 0.18'
end
