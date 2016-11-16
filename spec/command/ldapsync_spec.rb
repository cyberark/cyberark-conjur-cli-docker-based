require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do

  let (:policy_response) { { 'policy' => <<eop
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
    
    before do 
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_policy).with('default').and_return policy_response
    end

    it "shows the policy" do
      expect { invoke }.to write policy_response['policy']
    end
  end

end
