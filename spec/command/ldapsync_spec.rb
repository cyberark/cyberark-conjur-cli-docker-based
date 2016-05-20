require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do
  let(:json_response) { {
      'result' => {
          'actions' => [
              "user 'Guest'", "group 'Domain Computers'"
          ]
      }
  } }
  let(:yaml_response) { [
      'annotations' => {
          'ldap-sync/source' => '192.168.99.100:389',
          'ldap-sync/upstream-dn' => 'cn=Guest,dc=example,dc=org',
      }
  ].to_yaml }

  describe_command 'ldap-sync -f text' do
    it 'Prints out actions to be taken in text' do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return json_response
      expect { invoke }.to write("user 'Guest'\ngroup 'Domain Computers'")
    end
  end

  describe_command 'ldap-sync -f yaml' do
    it 'Prints out actions to be taken in text' do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return yaml_response
      expect { invoke }.to write(YAML.dump(yaml_response))
    end
  end
end
