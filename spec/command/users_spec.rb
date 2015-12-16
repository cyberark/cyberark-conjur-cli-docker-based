require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  let(:create_user_url) { "https://core.example.com/users" }
  let(:update_password_url) { "https://authn.example.com/users/password" }
  
  context "creating a user" do
    let(:new_user) { double("new-user") }
    before do
      expect(Conjur::Command::Users).to receive(:display).with(new_user)
    end

    [ "user:create", "user create" ].each do |cmd|
      describe_command "#{cmd} -p the-user" do
        it "Creates a user with a password obtained by prompting the user" do
          expect_any_instance_of(Conjur::API).to receive(:create_user).with("the-user", password: "the-password").and_return new_user
          expect(Conjur::Command::Users).to receive(:prompt_for_password).and_return "the-password"
  
          invoke
        end
      end
      describe_command "#{cmd} the-user" do
        it "Creates a user without a password" do
          expect_any_instance_of(Conjur::API).to receive(:create_user).with("the-user", {}).and_return new_user
          invoke
        end
      end
      describe_command "#{cmd} --uidnumber 12345 the-user" do
        it "Creates a user with specified uidnumber" do
          expect_any_instance_of(Conjur::API).to receive(:create_user).with("the-user", { uidnumber: 12345 }).and_return new_user
          invoke
        end
      end
      describe_command "#{cmd} --cidr 192.168.1.1,127.0.0.0/32 the-user" do
        it "Creates a user with specified CIDR" do
          expect_any_instance_of(Conjur::API).to receive(:create_user).with(
              "the-user", { cidr: ['192.168.1.1', '127.0.0.0/32'] }
          ).and_return new_user
          invoke
        end
      end
    end
  end

  context "updating user attributes" do
    describe_command "user update --uidnumber 12345 the-user" do
      it "updates the uidnumber" do
        stub_user = double()
        expect_any_instance_of(Conjur::API).to receive(:user).with("the-user").and_return stub_user
        expect(stub_user).to receive(:update).with(uidnumber: 12345).and_return ""
        expect { invoke }.to write "User updated"
      end
    end
    describe_command "user update --cidr 127.0.0.0/32 the-user" do
      it "updates the CIDR" do
        stub_user = double()
        expect_any_instance_of(Conjur::API).to receive(:user).with("the-user").and_return stub_user
        expect(stub_user).to receive(:update).with(cidr: ['127.0.0.0/32']).and_return ""
        expect { invoke }.to write "User updated"
      end
    end

    describe_command "user update --cidr all the-user" do
      it "resets the CIDR restrictions" do
        stub_user = double()
        expect_any_instance_of(Conjur::API).to receive(:user).with("the-user").and_return stub_user
        expect(stub_user).to receive(:update).with(cidr: []).and_return ""
        expect { invoke }.to write "User updated"
      end
    end
  end

  context "lookup per UID" do
    let(:search_result) { {id: "the-user"} }
    describe_command "user uidsearch 12345" do
      it "finds user" do
        expect_any_instance_of(Conjur::API).to receive(:find_users).with(uidnumber: 12345).and_return search_result
        expect { invoke }.to write(JSON.pretty_generate(search_result))
      end
    end
  end
  
  context "updating password" do
    before do
     expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: update_password_url,
        user: username, 
        password: api_key,
        headers: { },
        payload: "new-password"
       })
    end
    
    describe_command "user:update_password -p new-password" do
      it "PUTs the new password" do
        invoke
      end
    end
  
    describe_command "user:update_password" do
      it "PUTs the new password" do
        expect(Conjur::Command::Users).to receive(:prompt_for_password).and_return "new-password"

        invoke
      end
    end
  end
end
