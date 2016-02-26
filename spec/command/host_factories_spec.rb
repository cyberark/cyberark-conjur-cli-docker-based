require 'spec_helper'
require 'conjur/command/host_factories'

describe Conjur::Command::HostFactories, :logged_in => true do
  let (:group_memberships) { double(:group_memberships, :roleid => 'the-account:group:security_admin') }
  let (:current_role) { double(:current_role, :memberships => [ double(:current_role_role, roleid: 'the-account:user:dknuth') ]) }
  let (:group_members) { double(:layer_members, :member => double(:member, :roleid => 'the-account:user:dknuth'), :admin_option => true ) }
  let (:group) { double(:group, :exists? => true, :memberships => [group_memberships], :members => [group_members]) }
  let (:layer_members) { double(:layer_members, :member => double(:member, :roleid => 'the-account:group:security_admin'), :admin_option => true ) }
  let (:layer_role) { double(:layer_role, :members => [layer_members]) }
  let (:layer) { double(:layer, :exists? => true, :role => layer_role) }

  before do
    allow(Conjur::Command.api).to receive(:role).with("user:dknuth").and_return current_role
    allow(Conjur::Command.api).to receive(:role).with("the-account:group:the-group").and_return group
    allow(Conjur::Command.api).to receive(:layer).with("layer1").and_return layer
  end

  describe_command 'hostfactory:create --as-group the-group --layer layer1 hf1 ' do

    it 'calls api.create_host_factory and prints the results' do
      expect_any_instance_of(Conjur::API).to receive(:create_host_factory).and_return '{}'
      expect { invoke }.to write('{}')
    end
  end

  context 'command-line errors' do
    describe_command 'hostfactory:create hf1' do
      it "fails without owner" do
        expect {invoke}.to raise_error('Use --as-group or --as-role to indicate the host factory role') 
      end
    end
    describe_command 'hostfactory:create --as-group the-group hf' do
      it "fails without layer" do
        expect {invoke}.to raise_error('Provide at least one layer') 
      end
    end

  end

end
