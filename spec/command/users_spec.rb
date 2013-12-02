require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  let(:update_password_url) { "https://authn.example.com/users/password" }
  
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


  context "user:create" do
    context "immediately rejects logins with special symbols" do

      let(:errmsg) { /Sorry\, no special characters allowed in login/ }
      before(:each) { api.should_not_receive(:create_user) }

      describe_command "user:create with:colon" do
        it { expect { invoke }.to raise_error(ArgumentError, errmsg) }
      end
      describe_command "user:create with/slash" do
        it { expect { invoke }.to raise_error(ArgumentError, errmsg) }
      end
    end
  end
end
