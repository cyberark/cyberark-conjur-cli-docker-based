require 'spec_helper'

describe Conjur::Command::Elevate do
  describe_command "elevate user show alice" do
    include_context "with mock authn"
    
    let(:token) { {login: 'dknuth'} }
    before{
      expect(Conjur::Authn).to receive(:connect).and_return(api)
    }
    it "invokes the sub-command with X-Conjur-Privilege header" do
      allow_any_instance_of(Conjur::API).to receive(:token).and_return(token)
      expect(Conjur::Command).to receive(:api=) do |api|
        expect(api.api_key).to eq("sekrit")
        expect(api.privilege).to eq("sudo")
      end.and_call_original
      
      expect(RestClient::Request).to receive(:execute).with({
        method: :get,
        url: "https://core.example.com/users/alice",
        username: "dknuth",
        headers: {:authorization=>"Token token=\"eyJsb2dpbiI6ImRrbnV0aCJ9\"", x_conjur_privilege: "sudo"}
      }.merge(cert_store_options)).and_return(double(:response, body: "[]"))
      
      invoke
    end
  end
end
