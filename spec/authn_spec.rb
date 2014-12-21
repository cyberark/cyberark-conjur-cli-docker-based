require 'conjur/authn'
require 'conjur/config'

describe Conjur::Authn do
  let(:netrc) { Netrc.read '' }
  let(:authn_uri) { 'https://conjur.example.com/api/authn' }
  before do
    Conjur::Authn.instance_variable_set("@netrc", netrc)
    allow(Conjur::Authn::API).to receive(:host).and_return authn_uri
  end

  describe "credentials from environment" do
    before do
      Conjur::Authn.instance_variable_set("@credentials", nil)
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_LOGIN").and_return "the-login"
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_API_KEY").and_return "the-api-key"
    end

    after do
      Conjur::Authn.instance_variable_set("@credentials", nil)
    end

    it "are used to authn" do
      expect(Conjur::Authn.get_credentials).to eq([ "the-login", "the-api-key" ])
    end

    it "are not written to netrc" do
      expect(Conjur::Authn).not_to receive(:write_credentials)
      Conjur::Authn.get_credentials
    end
  end

  describe ".read_credentials" do
    shared_examples :read_credentials do
      it "finds the credentials" do
        creds = Conjur::Authn.read_credentials
        expect(creds.login).to eq 'user'
        expect(creds.password).to eq 'pass'
      end
    end

    context "when only the hostname not the url is the machine in the netrc file" do
      before do
        netrc['conjur.example.com'] = %w(user pass)
      end
      include_examples :read_credentials
    end

    context "when the url is the machine in the netrc file" do
      before do
        netrc[authn_uri] = %w(user pass)
      end
      include_examples :read_credentials
    end
  end

  describe "netrc" do
    let(:netrc) { nil }
    before do
      allow(Conjur::Config).to receive(:[]).with(:netrc_path).and_return path
    end

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
        expect(Netrc).to receive(:read).with(no_args).and_return netrc = double("netrc")
        expect(Conjur::Authn.netrc).to eq(netrc)
      end
    end
  end
end
