require 'spec_helper'
require 'conjur/dsl/runner'

describe Conjur::Command::Policy do
  context "when logged in", logged_in: true do
    let(:role) do
      double("role", exists?: true, api_key: "the-api-key", roleid: "the-role")
    end
    let(:resource) do
      double("resource", exists?: true).as_null_object
    end
    before {
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:exists?).and_call_original
      allow(File).to receive(:exists?).with("policy.rb").and_return true
      allow(File).to receive(:read).with("policy.rb").and_return "{}"
      allow_any_instance_of(Conjur::DSL::Runner).to receive(:api).and_return api
    }
    before {
      allow(api).to receive(:role).and_call_original
      allow(api).to receive(:resource).and_call_original
      allow(api).to receive(:role).with("the-account:policy:#{collection}/the-policy-1.0.0").and_return role
      allow(api).to receive(:resource).with("the-account:policy:#{collection}/the-policy-1.0.0").and_return resource
    }
    
    describe_command 'policy:load --collection the-collection http://example.com/policy.rb' do
      let(:collection) { "the-collection" }
      before {
        allow(File).to receive(:exists?).with("http://example.com/policy.rb").and_return false
        allow(URI).to receive(:parse).with("http://example.com/policy.rb").and_return double(:uri, read: "{}")
      }
      it "creates the policy" do
        expect(invoke).to eq(0)
      end
    end
    describe_command 'policy:load --collection the-collection policy.rb' do
      let(:collection) { "the-collection" }
      it "creates the policy" do
        expect(invoke).to eq(0)
      end
    end
    context "default collection" do
      let(:collection) { "alice@localhost" }
      before {
        stub_const("ENV", "USER" => "alice", "HOSTNAME" => "localhost")
      }
      describe_command 'policy:load --as-group the-group policy.rb' do
        let(:group) { double(:group, exists?: true) }
        it "creates the policy" do
          allow(Conjur::Command.api).to receive(:role).with("the-account:group:the-group").and_return group
          expect_any_instance_of(Conjur::DSL::Runner).to receive(:owner=).with("the-account:group:the-group")
          
          expect(invoke).to eq(0)
        end
      end
      describe_command 'policy:load policy.rb' do
        it "creates the policy with default collection" do
          expect(invoke).to eq(0)
        end
      end
    end
  end
end
