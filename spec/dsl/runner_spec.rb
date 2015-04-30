require 'spec_helper'
require 'conjur/dsl/runner'

describe Conjur::DSL::Runner, logged_in: true do
  include_context "fresh config"

  let(:filename) { nil }
  let(:runner) { Conjur::DSL::Runner.new script, filename }
  before {
    allow(Conjur).to receive(:account).and_return "the-account"
    allow(runner).to receive(:api).and_return api
  }
  context "nil record ids" do
    subject { runner.execute }
    context "creating a user" do
      let(:script) { "user" }
      it "isn't allowed" do
        expect{ subject }.to raise_error
      end
    end
    context "creating a resource" do
      let(:script) { "scope 'kitchen' do; resource 'food'; end" }
      it "creates resource with id matching the scope" do
        expect(api).to receive(:resource).with("the-account:food:kitchen").and_return double("kitchen-exists", :exists? => true)
        subject
      end
    end
    context "creating a layer" do
      let(:script) { "scope 'kitchen' do; layer; end" }
      it "creates layer with id matching the scope" do
        expect(api).to receive(:layer).with("kitchen").and_return double("kitchen-exists", :exists? => true)
        subject
      end
    end
  end
  context "creating user:alice" do
    let(:script) { "user 'alice'" }
    let(:alice) {
      Conjur::User.new("alice").tap do |user|
        user.attributes = { "api_key" => "the-api-key" }    
      end
    }
    it "should populate the root ownerid" do
      expect(api).to receive(:user).with("alice").and_return double("alice-exists", exists?: false)
      expect(api).to receive(:create_user).with(id: "alice", ownerid: "user:bob").and_return alice
      
      runner.owner = "user:bob"
      runner.execute
    end
    it "should store the api_key in the context keyed by roleid" do
      expect(api).to receive(:user).with("alice").and_return double("alice-exists", exists?: false)
      expect(api).to receive(:create_user).with(id: "alice").and_return alice
      
      runner.execute
      
      expect(runner.context['api_keys']).to eq({
        "the-account:user:alice" => "the-api-key"
      })
    end
  
    it "doesn't store default env and stack in context" do
      expect(runner.context).to_not have_key 'env'
      expect(runner.context).to_not have_key 'stack'
    end
  
    context "with non-default stack and env" do
      let(:runner) do
        Conjur::Config.merge env: 'baz', stack: 'bar'
        Conjur::Config.apply
        Conjur::DSL::Runner.new '', nil
      end
  
      it "stores them in context" do
        expect(runner.context['env']).to eq 'baz'
        expect(runner.context['stack']).to eq 'bar'
      end
    end
  
    context "with appliance url" do
      let(:appliance_url) { "https://conjur.example.com/api" }
      let(:runner) do
        Conjur::Config.merge appliance_url: appliance_url
        Conjur::Config.apply
        
        Conjur::DSL::Runner.new '', nil
      end
  
      it "stores appliance url in the context" do
        expect(runner.context['appliance_url']).to eq appliance_url
      end
    end
  end
end
