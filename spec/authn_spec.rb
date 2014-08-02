require 'conjur/authn'
require 'conjur/config'

describe Conjur::Authn do
  describe "credentials from environment" do
    before {
      Conjur::Authn.instance_variable_set("@credentials", nil)
      ENV.should_receive(:[]).with("CONJUR_AUTHN_LOGIN").and_return "the-login"
      ENV.should_receive(:[]).with("CONJUR_AUTHN_API_KEY").and_return "the-api-key"
    }
    after {
      Conjur::Authn.instance_variable_set("@credentials", nil)
    }
    it "are used to authn" do
      Conjur::Authn.get_credentials.should == [ "the-login", "the-api-key" ]
    end
    it "are not written to netrc" do
      Conjur::Authn.stub(:write_credentials).and_raise "should not write credentials"
      Conjur::Authn.get_credentials
    end
  end
  describe "netrc" do
    before {
      Conjur::Authn.instance_variable_set("@netrc", nil)
      Conjur::Config.should_receive(:[]).with(:netrc_path).and_return path
    }
    after {
      Conjur::Authn.instance_variable_set("@netrc", nil)
    }
    context "with specified netrc_path" do
      let(:path) { double("path") }
      it "consults Conjur::Config for netrc_path" do
        Netrc.should_receive(:read).with(path).and_return netrc = double("netrc")
        Conjur::Authn.netrc.should == netrc
      end
    end
    context "without specified netrc_path" do
      let(:path) { nil }
      it "uses default netrc path" do
        Netrc.should_receive(:read).with().and_return netrc = double("netrc")
        Conjur::Authn.netrc.should == netrc
      end
    end
  end
end
