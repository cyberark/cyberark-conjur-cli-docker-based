require 'spec_helper'

describe Conjur::Command::Hosts, logged_in: true do
  let(:collection_url) { "https://core.example.com/api/hosts" }


  context "updating host attributes" do
    describe_command "host update --cidr 127.0.0.0/32 the-user" do
      it "updates the CIDR" do
        stub_host = double()
        expect_any_instance_of(Conjur::API).to receive(:host).with("the-user").and_return stub_host
        expect(stub_host).to receive(:update).with(cidr: ['127.0.0.0/32']).and_return ""
        expect { invoke }.to write "Host updated"
      end
    end

    describe_command "host update --cidr all the-user" do
      it "resets the CIDR restrictions" do
        stub_host = double()
        expect_any_instance_of(Conjur::API).to receive(:host).with("the-user").and_return stub_host
        expect(stub_host).to receive(:update).with(cidr: []).and_return ""
        expect { invoke }.to write "Host updated"
      end
    end
  end

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
