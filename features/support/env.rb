require 'simplecov'
require 'aruba/cucumber'
require 'methadone/cucumber'
require 'cucumber/rspec/doubles'
require "json_spec/cucumber"

SimpleCov.start

Aruba.configure do |config|
  config.exit_timeout    = 15
  config.io_wait_timeout = 2
end
