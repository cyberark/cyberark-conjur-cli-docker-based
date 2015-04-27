require 'spec_helper'
require 'conjur/authn'
require 'conjur/config'
require 'conjur/command/rspec/output_matchers'

describe Conjur::Config do
  include_context "fresh config"

  describe ".default_config_files" do
    subject { Conjur::Config.default_config_files }
    let(:homedir) { '/home/isfake' }
    around do |example|
      realhome = ENV.delete 'HOME'
      ENV['HOME'] = homedir
      example.run
      ENV['HOME'] = realhome
    end

    let(:deprecation_warning) { "WARNING: .conjurrc file from current directory is used. This behaviour is deprecated. Use ENV['CONJURRC'] to explicitly define custom configuration file if needed" }

    shared_examples "no deprecation warning" do
      it "does not issue a deprecation warning" do
        expect { subject }.to_not write(deprecation_warning).to(:stderr)
      end
    end

    context "when CONJURRC is not set" do
      around do |example|
        oldrc = ENV.delete 'CONJURRC'


        example.run

        ENV['CONJURRC'] = oldrc
      end

      it { is_expected.to include('/etc/conjur.conf') }
      it { is_expected.to include("#{homedir}/.conjurrc") }
      it { is_expected.to include('.conjurrc') }

      before do
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('.conjurrc').and_return '.conjurrc'
      end

      context "When .conjurrc is present" do
        before { allow(File).to receive(:file?).with('.conjurrc').and_return true }
        it "Issues a deprecation warning" do 
          expect { subject }.to write(deprecation_warning).to(:stderr)
        end

        context "but the current directory is home" do
          before do
            allow(File).to receive(:expand_path).and_call_original
            allow(File).to receive(:expand_path).and_call_original
            allow(File).to receive(:expand_path).with('.conjurrc').and_return("#{homedir}/.conjurrc")
          end

          include_examples "no deprecation warning"
        end
      end

      context "When .conjurrc is missing" do
        before { allow(File).to receive(:file?).with('.conjurrc').and_return false }
        include_examples "no deprecation warning"
      end
    end

    context "when CONJURRC is set" do
      around do |example|
        oldrc = ENV['CONJURRC']
        ENV['CONJURRC']='stub_conjurrc'
        example.run
        ENV['CONJURRC'] = oldrc
      end
      it { is_expected.to include('/etc/conjur.conf') }
      it { is_expected.to include('stub_conjurrc') }
      it { is_expected.not_to include("#{homedir}/.conjurrc") }
      it { is_expected.not_to include('.conjurrc') }

      include_examples "no deprecation warning"
    end

    context "when CONJURRC is set to .conjurrc" do
      around do |example|
        oldrc = ENV['CONJURRC']
        ENV['CONJURRC']='.conjurrc'
        example.run
        ENV['CONJURRC'] = oldrc
      end
      before { allow(File).to receive(:file?).with('.conjurrc').and_return true }
      it { is_expected.to include('/etc/conjur.conf') }
      it { is_expected.to include('.conjurrc') }
      it { is_expected.not_to include("#{homedir}/.conjurrc") }

      include_examples "no deprecation warning"
    end
  end

  let(:load!) { Conjur::Config.load([ File.expand_path('conjurrc', File.dirname(__FILE__)) ]) }
  let(:cert_path) { File.expand_path('conjur-ci.pem', File.dirname(__FILE__)) }

  describe "#load" do
    it "resolves the cert_file" do
      load!
      
      expect(Conjur::Config[:cert_file]).to eq(cert_path)
    end
  end

  describe "#apply" do
    before { 
      allow(OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE).to receive(:add_file) 
    }

    context "ssl_certificate string" do
      let(:ssl_certificate){ 'the certificate' }
      let(:certificate){ double('Certificate') }
      before{
          Conjur::Config.class_variable_set('@@attributes', {'ssl_certificate' => ssl_certificate})
      }

      it 'trusts the certificate string' do
        expect(OpenSSL::X509::Certificate).to receive(:new).with(ssl_certificate).once.and_return certificate
        expect(OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE).to receive(:add_cert).with(certificate).once
        Conjur::Config.apply
      end
    end

    context "cert_file" do
      let(:cert_file) { "/path/to/cert.pem" }
      before { 
        Conjur::Config.class_variable_set("@@attributes", { 'cert_file' => cert_file })
      }
  
      it "trusts the cert_file" do
        expect(OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE).to receive(:add_file).with cert_file  
        Conjur::Config.apply
      end

      it "propagates the cert_file to Configuration.cert_file" do
        Conjur::Config.apply
        expect(Conjur.configuration.cert_file).to eq(cert_file)
      end
    end

    it "shadows rc with envars" do
      url = 'https://other-conjur.example.com'
      ENV['CONJUR_APPLIANCE_URL'] = url
      load!
      Conjur::Config.apply
      expect(Conjur.configuration.appliance_url).to eq(url)
    end
  end
end
