require 'spec_helper'

describe Conjur::Command::Groups, logged_in: true do
  describe_command "group:members:add group user:alice" do
    it "adds the role to the group" do
           RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: nil
      )
      invoke
    end
  end

  describe_command "group:members:add -a group user:alice" do
    it "adds the role to the group with admin option" do
       RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: true }
      )
      invoke
    end
  end
  describe_command "group:members:add -a group alice" do
    it "assumes that a nake member name is a user" do
           RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: true }
      )
      invoke
    end
  end

  describe_command "group:members:add -r group alice" do
    it "revokes the admin rights" do
       RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: false }
      )
      invoke
    end
  end
end
