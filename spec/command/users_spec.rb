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


  context "Deprovisioning" do
    let(:userid) { "badguy" }
    let(:roles_list) { ["user:badguy", "group:goodguys"].map {|r| double(roleid: r)  } }
    let(:user_role) { double(all: roles_list) }

    describe_command "user:deprovision badguy" do
      it 'revokes all roles from user' do
        api.should_receive(:role).with("user:"+userid).and_return(user_role)
        roles_list.each { |role|  
          role.should_receive(:revoke_from).with("user:"+userid)
        }
        invoke
      end
    end
  end
end
