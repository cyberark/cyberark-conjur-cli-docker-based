require "rubygems"
require "bundler/setup"

require "simplecov"
SimpleCov.start

module RSpec::Core::DSL
  def describe_command *argv, &block
    describe *argv do
      let(:invoke) do
        Conjur::CLI.error_device = $stderr
        Conjur::CLI.run argv 
      end
      instance_eval &block
    end
  end
end

require 'conjur/cli'
