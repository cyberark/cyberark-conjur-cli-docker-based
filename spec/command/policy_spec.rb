require 'spec_helper'
require 'conjur/dsl/runner'

describe Conjur::Command::Policy do
  context logged_in: true do
    let(:role) do
      double("role", exists?: true, api_key: "the-api-key", roleid: "the-role")
    end
    let(:resource) do
      double("resource", exists?: true).as_null_object
    end
    let(:name) { nil }
    before {
      File.stub(:read).with("policy-body").and_return "{}"
      Conjur::DSL::Runner.any_instance.stub(:api).and_return api
    }
    before {
      api.stub(:role).with("the-account:policy:#{collection}/the-policy-1.0.0").and_return role
      api.stub(:resource).with("the-account:policy:#{collection}/the-policy-1.0.0").and_return resource
      if name
        resource.should_receive(:[]).with(:name, name)
      end
    }
    
    describe_command 'policy:load --collection the-collection policy-body' do
      let(:collection) { "the-collection" }
      it "creates the policy" do
        invoke.should == 0
      end
    end
    context "default collection" do
      let(:collection) { "alice@localhost" }
      before {
        stub_const("ENV", "USER" => "alice", "HOSTNAME" => "localhost")
      }
      describe_command 'policy:load policy-body' do
        it "creates the policy with default collection" do
          invoke.should == 0
        end
      end
    end
  end
end