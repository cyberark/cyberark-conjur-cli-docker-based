require "rubygems"
require "bundler/setup"

require "simplecov"
SimpleCov.start

module RSpec::Core::DSL
  def describe_command name, *a, &block
    describe name, *a do
      let(:invoke) do
        Conjur::CLI.error_device = $stderr
        Conjur::CLI.run [name]
      end
      instance_eval &block
    end
  end
end

require 'conjur/cli'
