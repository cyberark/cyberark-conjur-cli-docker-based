require 'spec_helper'
require 'tempfile'
require 'write_expectation'

describe Conjur::Command::Authn do
  let(:netrcfile) { Tempfile.new 'authtest' }
  let(:netrc) { Netrc.read(netrcfile.path) }
  let(:host) { 'https://authn.example.com' }

  before do
    Conjur::Authn.stub netrc: netrc, host: host
  end

  context "when not logged in" do
    describe_command 'authn:whoami' do
      it "prints a descriptive error message and quits"
    end
  end

  context "when logged in" do
    let(:username) { 'dknuth' }
    let(:api_key) { 'sekrit' }
    before { netrc[host] = [username, api_key] }

    describe_command 'authn:logout' do
      it "deletes credentials" do
        invoke
        netrc[host].should_not be
      end
    end

    describe_command 'authn:whoami' do
      it "prints the current username to stdout" do
        expect { invoke }.to write username
      end
    end
  end
end
