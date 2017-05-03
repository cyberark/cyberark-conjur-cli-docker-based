$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

require 'json_spec/cucumber'

require 'aruba/cucumber'
require 'json_spec/cucumber'
require 'simplecov'

SimpleCov.start

ENV['CONJUR_APPLIANCE_URL'] ||= 'http://localhost/api/v6'
ENV['CONJUR_ACCOUNT'] ||= 'cucumber'

require 'conjur/cli'

Conjur::Config.load
Conjur::Config.apply

$netrc_file_path = ENV['CONJURRC'] || File.expand_path('~/.netrc')
if File.exists?($netrc_file_path)
  $netrc_file = File.read($netrc_file_path)
end

$conjur = Conjur::Authn.connect nil, noask: true

puts "Performing CLI tests as user '#{$conjur.current_role(Conjur.configuration.account).login}'"
