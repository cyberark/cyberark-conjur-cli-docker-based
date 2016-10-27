require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  let(:update_password_url) { "https://authn.example.com/users/password" }

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

  context 'rotating api key' do
    describe_command 'user rotate_api_key' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
                    method: :put,
                    url: 'https://authn.example.com/users/api_key',
                    user: username,
                    password: api_key,
                    headers: {},
                    payload: ''
                }).and_return double(:response, body: 'new api key')
        expect(Conjur::Authn).to receive(:save_credentials).with({
                    username: username,
                    password: 'new api key'
                })
      end

      it 'puts with basic auth' do
        invoke
      end
    end
  end
end
