require 'conjur/authn'
require 'conjur/config'

describe Conjur::Config do
  after {
    Conjur::Config.clear
  }
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
      OpenSSL::X509::Store.should_receive(:add_file).with cert_file
      
      Conjur::Config.apply
    end
  end
end
