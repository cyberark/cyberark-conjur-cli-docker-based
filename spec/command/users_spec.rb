require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  let (:rotate_api_key_url) { [Conjur.configuration.authn_url, account, 'api_key'].join('/') }
  let (:update_password_url) { [Conjur.configuration.authn_url, account, 'password'].join('/') }

  context "updating password" do
    before do
     expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: update_password_url,
        user: username, 
        password: api_key,
        headers: { },
        payload: "new-password",
        ssl_cert_store: cert_store
       })
    end
    
    describe_command "user:update_password -p new-password" do
      it "PUTs the new password" do
        invoke
      end
    end
  
    describe_command "user:update_password" do
      it "PUTs the new password" do
        expect(Conjur::Command::Users).to receive(:prompt_for_password).and_return "new-password"

        invoke
      end
    end
  end

  context 'rotating api key' do
    describe_command 'user rotate_api_key' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
                    method: :put,
                    url: rotate_api_key_url,
                    user: username,
                    password: api_key,
                    headers: {},
                    payload: '',
                    ssl_cert_store: cert_store
                }).and_return double(:response, body: 'new api key')
        expect(Conjur::Authn).to receive(:save_credentials).with({
                    username: username,
                    password: 'new api key'
                })
      end

      it 'puts with basic auth' do
        invoke
      end
    end
    describe_command 'user rotate_api_key --user non-existing' do
      before do
      expect(RestClient::Request).to receive(:execute).with({
            method: :head,
            url: "https://core.example.com/api/resources/#{account}/user/non-existing",
            headers: {authorization: "fakeauth"},
            username: username,
            ssl_cert_store: cert_store
        }).and_raise RestClient::ResourceNotFound
      end
      it 'rotate_api_key with non-existing --user option' do
        expect { invoke }.to raise_error(GLI::CustomExit, /User 'non-existing' not found/i)
      end
    end
  end
end
