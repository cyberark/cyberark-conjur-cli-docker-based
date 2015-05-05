require 'spec_helper'

describe Conjur::Command::Variables, logged_in: true do
  let(:host) { 'https://core.example.com' }
  let(:collection_url) { "#{host}/variables" }
  let(:mime_type) { 'text/plain' }
  let(:kind) { 'secret' }
  let(:base_payload) do
    { id: id, value: value, mime_type: mime_type, kind: kind }.tap do |t|
      group && t.merge(ownerid: group)
    end
  end
  let(:id) { 'the-id' }
  let(:variable) { post_response(id) }
  let (:group) { nil }
  let (:annotation) { {} }
  let (:value) { 'the-value' }
  let (:full_payload) { base_payload }
  
  context 'when there are command-line errors' do
    describe_command "variable:create -v the-value-1 the-id the-value-2" do
      it "complains about conflicting values" do
        expect { invoke }.to raise_error("Received conflicting value arguments")
      end
    end
  end

  context 'when there are no command-line errors' do
    
    before do
      allow(Conjur::Command::Variables).to receive(:prompt_for_id) { id }
      allow(Conjur::Command::Variables).to receive(:prompt_for_group) { group }
      allow(Conjur::Command::Variables).to receive(:prompt_for_kind) { kind }
      allow(Conjur::Command::Variables).to receive(:prompt_for_mime_type) { mime_type }
      allow(Conjur::Command::Variables).to receive(:prompt_for_annotations) { annotation }
      allow(Conjur::Command::Variables).to receive(:prompt_for_value)  { value }

      expect(RestClient::Request).to receive(:execute).with({
          method: :post,
          url: collection_url,
          headers: {},
          payload: full_payload
        }.merge(cert_store_options)).and_return(variable)
    end
    
    describe_command "variable:create the-different-id" do
      let (:id) { 'the-different-id' }
      it "propagates the user-assigned id" do
        expect { invoke }.to write({ id: 'the-different-id' }).to(:stdout)
      end
    end
    
    describe_command "variable:create the-id the-different-value" do
      let (:value) { 'the-different-value' }
      it "propagates the user-assigned id" do
        expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
      end
    end
    
    describe_command "variable:create -m application/json" do
      let (:mime_type) { 'application/json' }
      it "propagates the user-assigned MIME type" do
        expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
      end
    end
    
    describe_command "variable:create -k password" do
      let (:kind) { 'password' }
      it "propagates the user-assigned kind" do
        expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
      end
    end
    
    describe "in interactive mode" do
      after do
        expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
      end
      
      subject { Conjur::Command::Variables }
      
      context "when -i is omitted" do
        describe_command 'variable:create' do
          it { is_expected.to receive(:prompt_for_id) }
          it { is_expected.to receive(:prompt_for_group) }
          it { is_expected.to receive(:prompt_for_kind) }
          it { is_expected.to receive(:prompt_for_mime_type) }
          it { is_expected.to receive(:prompt_for_annotations) }
          it { is_expected.to receive(:prompt_for_value) }
        end
        
        describe_command 'variable:create the-id' do
          it { is_expected.not_to receive(:prompt_for_id) }
        end
        
        describe_command 'variable:create the-id the-value' do
          it { is_expected.not_to receive(:prompt_for_value) }
        end
        
        describe_command 'variable:create -m application/json' do
          let (:mime_type) { 'application/json' }
          it { is_expected.not_to receive(:prompt_for_mime_type) }
        end
        
        describe_command 'variable:create -k password' do
          let (:kind) { 'password' }
          it { is_expected.not_to receive(:prompt_for_kind) }
        end
        
        describe_command 'variable:create -v the-value' do
          it { is_expected.not_to receive(:prompt_for_value) }
        end

        describe_command 'variable:create --as-group the-group' do
          before do
            allow(RestClient::Request).to receive(:execute).with({
                method: :head,
                url: 'https://authz.example.com/the-account/roles/group/the-group',
                headers: {}
              }.merge(cert_store_options)).and_return(OpenStruct.new(headers: {}, body: '{}'))
          end
            
          let (:full_payload) { base_payload.merge(ownerid: 'the-account:group:the-group') }

          it { is_expected.not_to receive(:prompt_for_group) }
        end

        describe_command 'variable:create --as-role the-account:group:the-group' do
          before do
            allow(RestClient::Request).to receive(:execute).with({
                method: :head,
                url: 'https://authz.example.com/the-account/roles/group/the-group',
                headers: {}
              }.merge(cert_store_options)).and_return(OpenStruct.new(headers: {}, body: '{}'))
          end
            
          let (:full_payload) { base_payload.merge(ownerid: 'the-account:group:the-group') }

          it { is_expected.not_to receive(:prompt_for_group) }
        end
        
      end
      
      context "when -i is provided" do
        describe_command 'variable:create -i the-id the-value' do
          it { is_expected.not_to receive(:prompt_for_id) }
          it { is_expected.not_to receive(:prompt_for_value) }
          it { is_expected.to receive(:prompt_for_group) }
          it { is_expected.to receive(:prompt_for_mime_type) }
          it { is_expected.to receive(:prompt_for_kind) }
          it { is_expected.to receive(:prompt_for_annotations) }
        end
      end
      
    end
    
  end
end
