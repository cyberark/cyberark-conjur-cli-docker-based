require 'conjur/authn'
require 'conjur/config'

describe Conjur::Authn do
  let(:netrc) { Netrc.read '' }
  before do
    Conjur::Authn.instance_variable_set("@netrc", netrc)
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
  
  describe "netrc" do
    describe "fail_if_world_readable" do
      let(:path) { "the-path" }
      around { |example|
        host_os = RbConfig::CONFIG["host_os"]
        RbConfig::CONFIG["host_os"] = os
        begin
          example.run
        ensure 
          RbConfig::CONFIG["host_os"] = host_os
        end
      }
      context "on Windows" do
        let(:os) { "mswin" }
        it "bypasses the readability check" do
          Conjur::Authn.send :fail_if_world_readable, path
        end
      end
      context "on Linux" do
        let(:os) { "linux" }
        it "raises an error if the file is world readable" do
          expect(File).to receive(:world_readable?).with(path).and_return(true)
          expect { Conjur::Authn.send :fail_if_world_readable, path }.to raise_error("netrc (the-path) shouldn't be world-readable")
        end
      end
    end

    context "loading" do
      let(:netrc) { nil }
      before do
        allow(Conjur::Config).to receive(:[]).with(:netrc_path).and_return path
      end
      
      context "with specified netrc_path" do
        let(:path) { "/a/dummy/netrc/path" }
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
end
