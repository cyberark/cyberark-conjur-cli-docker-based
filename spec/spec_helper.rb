require "rubygems"
require "bundler/setup"
require 'tempfile'

require "simplecov"
SimpleCov.start

module RSpec::Core::DSL
  def describe_command *argv, &block
    describe *argv do
      let(:invoke) do
        Conjur::CLI.error_device = $stderr
        Conjur::CLI.run argv.clone
      end
      instance_eval &block
    end
  end
end

shared_context "with fake endpoints and test config" do
  let(:authn_host) { 'https://authn.example.com' }
  let(:authz_host) { 'https://authz.example.com' }
  let(:core_host) { 'https://core.example.com' }
  before do
    Conjur::Authn::API.stub host: authn_host
    Conjur::Authz::API.stub host: authz_host
    Conjur::Core::API.stub host: core_host

    ENV['GLI_DEBUG'] = 'true'
  end
end

shared_context "with mock authn" do
  include_context "with fake endpoints and test config"
  let(:netrcfile) { Tempfile.new 'authtest' }
  let(:netrc) { Netrc.read(netrcfile.path) }
  let(:account) { 'the-account' }
  before do
    Conjur::Core::API.stub conjur_account: account
    Conjur::Authn.stub netrc: netrc, host: authn_host
    Conjur::Config.merge 'account' => account
  end

end

shared_context "when logged in", logged_in: true do
  include_context "with mock authn"
  let(:username) { 'dknuth' }
  let(:api_key) { 'sekrit' }
  let(:api) { Conjur::API.new_from_token({ 'data' => username }) }
  before do
    netrc[authn_host] = [username, api_key]
    Conjur::Command.stub api: api
  end
end

shared_context "when not logged in", logged_in: false do
  include_context "with mock authn"
end

require 'write_expectation'

require 'conjur/cli'
