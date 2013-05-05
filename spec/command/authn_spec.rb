require 'spec_helper'
require 'tempfile'

describe Conjur::Command::Authn do
  let(:netrcfile) { Tempfile.new 'authtest' }
  before do
    Conjur::Authn.stub netrc: Netrc.read(netrcfile.path)
  end
  describe_command 'authn:logout' do
    it "deletes credentials" do
      Conjur::Authn.should_receive :delete_credentials
      invoke
    end
  end
end
