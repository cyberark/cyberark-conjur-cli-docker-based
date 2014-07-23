require 'conjur/authn'
require 'conjur/config'
require 'conjur/command/rspec/output_matchers'

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

    let(:deprecation_warning) { "WARNING: .conjurrc file from current directory is used. This behaviour is deprecated. Use ENV['CONJURRC'] to explicitly define custom configuration file if needed" }
    context "when CONJURRC is not set" do
      around do |example|
        oldrc = ENV.delete 'CONJURRC'
        example.run
        ENV['CONJURRC'] = oldrc
      end

      it { should include('/etc/conjur.conf') }
      it { should include('/home/isfake/.conjurrc') }
      it { should include('.conjurrc') }
      context "When .conjurrc is present" do
        before { File.stub(:file?).with('.conjurrc').and_return true }
        it "Issues a deprecation warning" do 
          expect { subject }.to write(deprecation_warning).to(:stderr)
        end
      end 
      context "When .conjurrc is missing" do
        before { File.stub(:file?).with('.conjurrc').and_return false }
        it "Does not issue a deprecation warning" do 
          expect { subject }.to_not write(deprecation_warning).to(:stderr)
        end
      end
    end

    context "when CONJURRC is set" do
      around do |example|
        oldrc = ENV['CONJURRC']
        ENV['CONJURRC']='stub_conjurrc'
        example.run
        ENV['CONJURRC'] = oldrc
      end
      it { should include('/etc/conjur.conf') }
      it { should include('stub_conjurrc') }
      it { should_not include('/home/isfake/.conjurrc') }
      it { should_not include('.conjurrc') }
      it "Does not issue a deprecation warning" do
        expect { subject }.to_not write(deprecation_warning).to(:stderr)
      end
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

    it "shadows rc with envars" do
      url = 'https://other-conjur.example.com'
      ENV['CONJUR_APPLIANCE_URL'] = url
      load!
      Conjur::Config.apply
      expect(Conjur.configuration.appliance_url).to eq url
    end
  end
end
