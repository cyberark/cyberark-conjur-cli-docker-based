require 'spec_helper'

describe Conjur::Command::Hosts, logged_in: true do
  let(:collection_url) { "https://core.example.com/api/hosts" }

  context 'rotating api key' do
    describe_command 'host rotate_api_key --host redis001' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
          method: :head,
          url: "https://core.example.com/api/resources/#{account}/host/redis001",
          headers: {
            authorization: "fakeauth",
          },
          username: "dknuth",
          ssl_cert_store: cert_store
        }).and_return true
        expect(RestClient::Request).to receive(:execute).with({
            method: :put,
            url: "https://core.example.com/api/authn/#{account}/api_key?role=#{account}:host:redis001",
            headers: {
              authorization: "fakeauth",
            },
            payload: '',
            username: "dknuth",
            ssl_cert_store: cert_store
        }).and_return double(:response, body: 'new api key')
      end

      it 'puts with basic auth' do
        invoke
      end
    end

    describe_command 'host rotate_api_key --host non-existing' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
                  method: :head,
                  url: "https://core.example.com/api/resources/#{account}/host/non-existing",
                  headers: {authorization: "fakeauth"},
                  username: username,
                  ssl_cert_store: cert_store
              }).and_raise RestClient::ResourceNotFound
      end
      it 'rotate_api_key with non-existing --host option' do
        expect { invoke }.to raise_error(GLI::CustomExit, /Host 'non-existing' not found/i)
      end
    end
  end
end
