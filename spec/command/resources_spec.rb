require 'spec_helper'

describe Conjur::Command::Resources, logged_in: true do

  describe_command "resource:check food bacon fry" do
    it "performs a permission check for the logged-in user" do
      api.should_receive(:resource).with("the-account:food:bacon").and_return bacon = double("the-account:food:bacon")
      bacon.should_receive(:permitted?).with("fry")
      
      invoke
    end
  end
  
  describe_command "resource:check -r test:the-role food bacon fry" do
    it "performs a permission check for a specified role" do
      api.should_receive(:role).with("test:the-role").and_return role = double("the-account:test:the-role")

      role.should_receive(:permitted?).with("food", "bacon", "fry")
      
      invoke
    end
  end
end