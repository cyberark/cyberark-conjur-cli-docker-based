require 'spec_helper'

tmpdir = Dir.mktmpdir

describe Conjur::Command::Init do
  context logged_in: false do
    before {
      File.stub(:exists?).and_return false
    }
    context "auto-fetching fingerprint" do
      before {
        HighLine.any_instance.stub(:ask).with("Enter the hostname (and optional port) of your Conjur endpoint: ").and_return "the-host"
        Object.any_instance.should_receive(:`).with("echo | openssl s_client -connect the-host:443  2>/dev/null | openssl x509 -fingerprint").and_return "the-fingerprint"
        HighLine.any_instance.stub(:ask).with(/^Trust this certificate/).and_return "yes"
      }
      describe_command 'init' do
        it "fetches account and writes config file" do
          # Stub hostname
          Conjur::Core::API.should_receive(:info).and_return "account" => "the-account"
          File.should_receive(:open)
          invoke
        end
      end
      describe_command 'init -a the-account' do
        it "writes config file" do
          File.should_receive(:open)
          invoke
        end
      end
    end
    describe_command 'init -a the-account -h foobar' do
      it "can't get the cert" do
        expect { invoke }.to raise_error(GLI::CustomExit, /unable to retrieve certificate/i)
      end
    end
    describe_command 'init -a the-account -h google.com' do
      it "writes the config and cert" do
        HighLine.any_instance.stub(:ask).and_return "yes"
        File.should_receive(:open).twice
        invoke
      end
    end
    describe_command 'init -a the-account -h localhost -c the-cert' do
      it "writes config and cert files" do
        File.should_receive(:open).twice
        invoke
      end
    end
    context "in a temp dir" do
      describe_command "init -f #{tmpdir}/.conjurrc -a the-account -h localhost -c the-cert" do
        it "writes config and cert files" do
          invoke
          
          File.read(File.join(tmpdir, ".conjurrc")).should == """---
account: the-account
plugins:
- environment
- layer
- key-pair
- pubkeys
appliance_url: https://localhost/api
cert_file: #{tmpdir}/conjur-the-account.pem
"""
          File.read(File.join(tmpdir, "conjur-the-account.pem")).should == "the-cert\n"
        end
      end
    end
  end
end
