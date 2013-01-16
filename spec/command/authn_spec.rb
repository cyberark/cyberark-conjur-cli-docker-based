require 'spec_helper'
require 'tempfile'

describe Conjur::Command::Authn do
  let(:netrcfile) { Tempfile.new 'authtest' }
  before do
    Conjur::Auth.stub netrc: Netrc.read(netrcfile.path)
  end
  describe_command 'auth:logout' do
    it "deletes credentials" do
      Conjur::Auth.should_receive :delete_credentials
      invoke
    end
  end
end
