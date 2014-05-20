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

  describe "#load" do
    it "resolves the cert_file" do
      Conjur::Config.load([ File.expand_path('conjurrc', File.dirname(__FILE__)) ])
      
      Conjur::Config[:cert_file].should == File.expand_path('conjur-ci.pem', File.dirname(__FILE__))
    end
  end
  describe "#apply" do
    let(:cert_file) { "/path/to/cert.pem" }
    it "trusts the cert_file" do
      Conjur::Config.class_variable_set("@@attributes", { 'cert_file' => cert_file })
      OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.should_receive(:add_file).with cert_file  
      Conjur::Config.apply
    end
  end
end
