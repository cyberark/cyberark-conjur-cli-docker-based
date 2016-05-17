require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do
  describe_command 'ldap-sync --dry-run' do
    it 'Prints out actions to be taken in text' do
      expect { invoke }.to write('{:"dry-run"=>true, :profile=>"default", :format=>"text"}')
    end
  end
end
