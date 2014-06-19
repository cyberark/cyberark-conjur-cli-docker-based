module RSpec::Core::DSL
  def describe_command *argv, &block
    describe *argv do
      let(:invoke) do
        Conjur::CLI.error_device = $stderr
        # TODO: allow proper handling of description like "audit:send 'hello world'"
        Conjur::CLI.run argv.first.split(' ')
      end
      instance_eval &block
    end
  end
end
