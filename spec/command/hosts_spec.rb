require 'spec_helper'

describe Conjur::Command::Hosts, logged_in: true do
  let(:collection_url) { "https://core.example.com/api/hosts" }

  context 'rotating api key' do
    describe_command 'host rotate_api_key --host redis001' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
          method: :head,
          url: 'https://core.example.com/api/hosts/redis001',
          headers: {}
        }).and_return true
        expect(RestClient::Request).to receive(:execute).with({
            method: :put,
            url: 'https://authn.example.com/users/api_key?id=host%2Fredis001',
            headers: {},
            payload: ''
        }).and_return double(:response, body: 'new api key')
      end

      it 'puts with basic auth' do
        invoke
      end
    end
  end
end
