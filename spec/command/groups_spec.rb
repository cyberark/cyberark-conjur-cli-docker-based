require 'spec_helper'

describe Conjur::Command::Groups, logged_in: true do
  describe_command "group:members:add group role" do
    it "adds the role to the group" do
           RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=role",
        headers: {},
        payload: nil
      )
      invoke
    end
  end

  describe_command "group:members:add -a group role" do
    it "adds the role to the group with admin option" do
           RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=role",
        headers: {},
        payload: { admin_option: true }
      )
      invoke
    end
  end

  describe_command "group:members:add -r group role" do
    it "revokes the admin rights" do
           RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=role",
        headers: {},
        payload: { admin_option: false }
      )
      invoke
    end
  end
end
