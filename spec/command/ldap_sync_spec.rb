require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do
  let (:policy_response) { { 'ok' => true, 'events' => [], 'policy' => <<eop
"---
- !user
  annotations:
    ldap-sync/source: ldap-server:389
    ldap-sync/upstream-dn: CN=Administrator,OU=functest,OU=testdata,OU=dev-ci,DC=dev-ci,DC=conjur
  id: Administrator
  uidnumber:"}
eop
  }
}

  describe_command "ldap-sync policy show" do

    context "on a server that supports LDAP sync" do
      before do 
        expect_any_instance_of(Conjur::API).to receive(:ldap_sync_policy).with(config_name: 'default').and_return policy_response
      end
      
      it "shows the policy" do
        expect { invoke }.to write policy_response['policy']
      end
    end

    context "on a server that doesn't support LDAP sync" do
      before do
        expect_any_instance_of(Conjur::API).to receive(:ldap_sync_policy).and_raise(RestClient::ResourceNotFound)
      end

      it "shows an error message" do
        expect {invoke}.to raise_error(GLI::CustomExit, /LDAP sync is not supported by the server/)
      end
    end
  end
end
