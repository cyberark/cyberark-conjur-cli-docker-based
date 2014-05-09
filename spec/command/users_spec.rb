require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  let(:create_user_url) { "https://core.example.com/users" }
  let(:update_password_url) { "https://authn.example.com/users/password" }
  
  context "creating a user" do
    let(:new_user) { double("new-user") }
    before do
      Conjur::Command::Users.should_receive(:display).with(new_user)
    end

    [ "user:create", "user create" ].each do |cmd|
      describe_command "#{cmd} the-user -p" do
        it "Creates a user with a password obtained by prompting the user" do
          Conjur::API.any_instance.should_receive(:create_user).with("the-user", password: "the-password").and_return new_user
          Conjur::Command::Users.should_receive(:prompt_for_password).and_return "the-password"
  
          invoke
        end
      end
      describe_command "#{cmd} the-user -p new-password" do
        it "Creates a user without a password" do
          Conjur::API.any_instance.should_receive(:create_user).with("the-user", {}).and_return new_user
          invoke
        end
      end
    end
  end
  
  context "updating password" do
    before do
     RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: update_password_url,
        user: username, 
        password: api_key,
        headers: { },
        payload: "new-password"
      )
    end
    
    describe_command "user:update_password -p new-password" do
      it "PUTs the new password" do
        invoke
      end
    end
  
    describe_command "user:update_password" do
      it "PUTs the new password" do
        Conjur::Command::Users.should_receive(:prompt_for_password).and_return "new-password"

        invoke
      end
    end
  end
end