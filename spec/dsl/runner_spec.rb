require 'spec_helper'
require 'conjur/dsl/runner'

describe Conjur::DSL::Runner, logged_in: true do
  let(:filename) { nil }
  let(:runner) { Conjur::DSL::Runner.new script, filename }
  let(:script) { "user 'alice'" }
  let(:alice) {
    Conjur::User.new("alice").tap do |user|
      user.attributes = { "api_key" => "the-api-key" }    
    end
  }
  before {
    Conjur.stub(:account).and_return "the-account"
    runner.stub(:api).and_return api
  }
  it "should populate the root ownerid" do
    api.should_receive(:user).with("alice").and_return double("alice-exists", exists?: false)
    api.should_receive(:create_user).with(id: "alice", ownerid: "user:bob").and_return alice
    
    runner.owner = "user:bob"
    runner.execute
  end
  it "should store the api_key in the context keyed by roleid" do
    api.should_receive(:user).with("alice").and_return double("alice-exists", exists?: false)
    api.should_receive(:create_user).with(id: "alice").and_return alice
    
    runner.execute
    
    runner.context['api_keys'].should == {
      "the-account:user:alice" => "the-api-key"
    }
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

    it "stores ther in context" do
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
