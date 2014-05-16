require 'spec_helper'

describe Conjur::Command::Variables, logged_in: true do
  let(:collection_url) { "https://core.example.com/variables" }

  let(:base_payload) { { mime_type: 'text/json', kind: 'password' } }

  describe_command "variable:create -m text/json -k password" do
    it "lets the server assign the id" do
     RestClient::Request.should_receive(:execute).with(
        method: :post,
        url: collection_url,
        headers: {},
        payload: base_payload
      ).and_return(post_response('assigned-id'))

      expect { invoke }.to write({ id: 'assigned-id' }).to(:stdout)
    end
  end
  describe_command "variable:create -m text/json -k password the-id" do
    it "propagates the user-assigned id" do
     RestClient::Request.should_receive(:execute).with(
        method: :post,
        url: collection_url,
        headers: {},
        payload: base_payload.merge({ id: 'the-id' })
      ).and_return(post_response('the-id'))

      expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
    end
  end


  describe_command "variable:create" do
    it "provides default values for optional parameters mime_type and kind" do
      RestClient::Request.should_receive(:execute).with(
        method: :post,
        url: collection_url,
        headers: {},
        payload: { mime_type: 'text/plain', kind: 'secret'}
        ).and_return(post_response('the-id'))
      expect { invoke }.to write # invoke_silently
    end
  end


end
