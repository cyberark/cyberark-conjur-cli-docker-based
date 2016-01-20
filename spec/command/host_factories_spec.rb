require 'spec_helper'
require 'conjur/command/host_factories'

describe Conjur::Command::HostFactories, :logged_in => true do

  describe_command 'hostfactory:create --as-group the-group hf1' do
    let (:group) { double(:group, :exists? => true) }

    it 'calls api.create_host_factory and prints the results' do
      allow(Conjur::Command.api).to receive(:role).with("the-account:group:the-group").and_return group
      expect_any_instance_of(Conjur::API).to receive(:create_host_factory).and_return '{}'
      expect { invoke }.to write('{}')
    end
  end

end
