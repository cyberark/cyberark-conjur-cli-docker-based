require 'conjur/authn'
require 'conjur/config'

describe Conjur::Authn do
  describe "credentials from environment" do
    before {
      Conjur::Authn.instance_variable_set("@credentials", nil)
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_LOGIN").and_return "the-login"
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_API_KEY").and_return "the-api-key"
    }
    after {
      Conjur::Authn.instance_variable_set("@credentials", nil)
    }
    it "are used to authn" do
      expect(Conjur::Authn.get_credentials).to eq([ "the-login", "the-api-key" ])
    end
    it "are not written to netrc" do
      allow(Conjur::Authn).to receive(:write_credentials).and_raise "should not write credentials"
      Conjur::Authn.get_credentials
    end
  end
  describe "netrc" do
    before {
      Conjur::Authn.instance_variable_set("@netrc", nil)
      expect(Conjur::Config).to receive(:[]).with(:netrc_path).and_return path
    }
    after {
      Conjur::Authn.instance_variable_set("@netrc", nil)
    }
    context "with specified netrc_path" do
      let(:path) { double("path") }
      it "consults Conjur::Config for netrc_path" do
        expect(Netrc).to receive(:read).with(path).and_return netrc = double("netrc")
        expect(Conjur::Authn.netrc).to eq(netrc)
      end
    end
    context "without specified netrc_path" do
      let(:path) { nil }
      it "uses default netrc path" do
        expect(Netrc).to receive(:read).with().and_return netrc = double("netrc")
        expect(Conjur::Authn.netrc).to eq(netrc)
      end
    end
  end
end
