require 'spec_helper'
require 'conjur/dsl/runner'

describe Conjur::DSL::Runner, logged_in: true do
  let(:filename) { nil }
  let(:runner) { Conjur::DSL::Runner.new script, filename }
  let(:script) { "user 'alice'" }
  before {
    Conjur.stub(:account).and_return "the-account"
    runner.stub(:api).and_return api
  }
  it "should store the api_key in the context keyed by roleid" do
    user = Conjur::User.new("alice")
    user.attributes = { "api_key" => "the-api-key" }
    
    api.should_receive(:user).with("alice").and_return double("alice-exists", exists?: false)
    api.should_receive(:create_user).with(id: "alice").and_return user
    
    runner.execute
    
    runner.context['api_keys'].should == {
      "the-account:user:alice" => "the-api-key"
    }
  end
end