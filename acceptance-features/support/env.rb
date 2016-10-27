$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

require 'conjur/cli'
require 'conjur/api'
require 'aruba/cucumber'
require 'json_spec/cucumber'
