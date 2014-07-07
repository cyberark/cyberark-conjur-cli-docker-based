require 'conjur/authn'
require 'conjur/config'

describe Conjur::Config do
  after {
    Conjur::Config.clear
  }

  describe ".default_config_files" do
    subject { Conjur::Config.default_config_files }
    around do |example|
      realhome = ENV.delete 'HOME'
      ENV['HOME'] = '/home/isfake'
      example.run
      ENV['HOME'] = realhome
    end

    context "when CONJURRC is not set" do
      around do |example|
        oldrc = ENV.delete 'CONJURRC'
        example.run
        ENV['CONJURRC'] = oldrc
      end

      it { should include('/home/isfake/.conjurrc') }
    end
  end

  let(:load!) { Conjur::Config.load([ File.expand_path('conjurrc', File.dirname(__FILE__)) ]) }
  let(:cert_path) { File.expand_path('conjur-ci.pem', File.dirname(__FILE__)) }

  describe "#load" do
    it "resolves the cert_file" do
      load!
      
      Conjur::Config[:cert_file].should == cert_path
    end
  end
  describe "#apply" do
    before { OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.stub(:add_file) }

    let(:cert_file) { "/path/to/cert.pem" }
    it "trusts the cert_file" do
      Conjur::Config.class_variable_set("@@attributes", { 'cert_file' => cert_file })
      OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.should_receive(:add_file).with cert_file  
      Conjur::Config.apply
    end

    # is it something we want? I just spec it here to document it -div
    it "shadows envars with rc" do
      url = 'https://other-conjur.example.com'
      ENV['CONJUR_APPLIANCE_URL'] = url
      load!
      Conjur::Config.apply
      expect(Conjur.configuration.appliance_url).to_not eq url
    end
  end
end
