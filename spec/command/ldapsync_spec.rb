require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do
  let(:timestamp) { Time.now.to_s }
  let(:json_response) { {
      'events' => [
        { "timestamp" => timestamp,
          "severity" => "info",
          "message" => "Performing sync"
        }
      ],
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

  describe_command 'ldap-sync now -f text' do
    before {
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return json_response
    }
    it 'prints out diagnostic events' do
      expect { invoke }.to write([ timestamp, "info", "Performing sync" ].join("\t"))
    end
    it 'prints out actions as text' do
      expect { invoke }.to write("user 'Guest'\ngroup 'Domain Computers'")
    end
  end

  describe_command 'ldap-sync now -f yaml' do
    it 'prints out actions as unparsed yaml' do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return yaml_response
      expect { invoke }.to write(yaml_response)
    end
  end
end
