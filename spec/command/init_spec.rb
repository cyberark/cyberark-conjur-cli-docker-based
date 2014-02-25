require 'spec_helper'

tmpdir = Dir.mktmpdir

describe Conjur::Command::Init do
  context logged_in: false do
    before {
      File.stub(:exists?).and_return false
    }
    describe_command 'init -a the-account' do
      it "writes config file" do
        # Stub hostname
        HighLine.any_instance.stub(:ask).and_return ""
        File.should_receive(:open)
        invoke
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
