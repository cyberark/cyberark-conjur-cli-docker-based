require "rubygems"
require "bundler/setup"

require "simplecov"
SimpleCov.start

module RSpec::Core::DSL
  def describe_command name, *a, &block
    describe name, *a do
      let(:invoke) { Conjur::CLI.run [name] }
      instance_eval &block
    end
  end
end

require 'conjur/cli'
