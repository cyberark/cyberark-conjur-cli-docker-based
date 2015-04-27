require 'spec_helper'

describe Conjur::Command::Variables, logged_in: true do
  let(:collection_url) { "https://core.example.com/variables" }
  let(:base_payload) { { mime_type: 'text/json', kind: 'password' } }
  let(:id) { 'the-id' }
  let(:variable) { post_response(id) }

  describe_command "variable:create -m text/json -k password" do
    let(:id) { 'assigned-id' }
    it "lets the server assign the id" do
     expect(RestClient::Request).to receive(:execute).with(hash_including(
        method: :post,
        url: collection_url,
        headers: {},
        payload: base_payload
      )).and_return(variable)

      expect { invoke }.to write({ id: 'assigned-id' }).to(:stdout)
    end
  end

  describe_command "variable:create -m text/json -k password the-id" do
    it "propagates the user-assigned id" do
     expect(RestClient::Request).to receive(:execute).with(hash_including(
        method: :post,
        url: collection_url,
        headers: {},
        payload: base_payload.merge({ id: 'the-id' })
      )).and_return(variable)

      expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
    end
  end

  describe_command "variable:create -m text/json -k password the-id the-value" do
    it "propagates the user-assigned id and value" do
     expect(RestClient::Request).to receive(:execute).with(hash_including(
        method: :post,
        url: collection_url,
        headers: {},
        payload: base_payload.merge({ id: 'the-id', value: 'the-value' })
      )).and_return(variable)

      expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
    end
  end

  describe_command "variable:create -v the-value-1 the-id the-value-2" do
    it "complains about conflicting values" do
      expect { invoke }.to raise_error("Received conflicting value arguments")
    end
  end

  describe_command "variable:create the-id -v the-value" do
    it "complains about extra arguments" do
      expect { invoke }.to raise_error("Received extra arguments 'the-value'")
    end
  end

  describe_command "variable:create" do
    it "provides default values for optional parameters mime_type and kind" do
      expect(RestClient::Request).to receive(:execute).with(hash_including(
        method: :post,
        url: collection_url,
        headers: {},
        payload: { mime_type: 'text/plain', kind: 'secret'}
        )).and_return(variable)
      expect { invoke }.to write # invoke_silently
    end
  end
end
