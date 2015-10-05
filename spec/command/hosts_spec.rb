require 'spec_helper'

describe Conjur::Command::Hosts, logged_in: true do
  let(:collection_url) { "https://core.example.com/hosts" }
  
  describe_command "host:create" do
    it "lets the server assign the id" do
     expect(RestClient::Request).to receive(:execute).with({
        method: :post,
        url: collection_url,
        headers: {},
        payload: {}
        }).and_return(post_response('assigned-id'))

      expect { invoke }.to write({ id: 'assigned-id' }).to(:stdout)
    end
  end
  describe_command "host:create the-id" do
    it "propagates the user-assigned id" do
     expect(RestClient::Request).to receive(:execute).with({
        method: :post,
        url: collection_url,
        headers: {},
        payload: { id: 'the-id' }
      }).and_return(post_response('the-id'))

      expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
    end
  end
end
