require 'spec_helper'
require 'tempfile'
require 'write_expectation'

describe Conjur::Command::Authn do
  let(:netrcfile) { Tempfile.new 'authtest' }
  let(:netrc) { Netrc.read(netrcfile.path) }
  let(:host) { 'https://authn.example.com' }
  let(:account) { 'the-account' }
  before { Conjur::Core::API.stub conjur_account: account }

  before do
    Conjur::Authn.stub netrc: netrc, host: host
  end

  context "when not logged in" do
    describe_command 'authn:whoami' do
      it "errors out" do
        expect{ invoke }.to write(/not logged in/i).to :stderr
      end
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
      it "prints the current account and username to stdout" do
        expect { invoke }.to write({ account: account, username: username }.to_json)
      end
    end
  end
end
