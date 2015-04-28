require 'spec_helper'

describe Conjur::Command::Groups, logged_in: true do
  describe_command 'group create --gidnumber 12345 some-group' do
    it "creates the group with a specified gidnumber" do
      expect_any_instance_of(Conjur::API).to receive(:create_group).with('some-group', gidnumber: 12345).and_return "something"
      expect { invoke }.to write "something"
    end
  end

  describe_command 'group update --gidnumber 12345 some-group' do
    it "updates the gid" do
      expect_any_instance_of(Conjur::API).to \
          receive(:group).with('some-group').and_return(group = double("group"))
      expect(group).to receive(:update).with(gidnumber: 12_345)
      expect { invoke }.to write "GID set"
    end
  end

  context "lookup by GID" do
    let(:search_result) { %w(g1 g2) }
    describe_command "group gidsearch 12345" do
      it "finds the groups" do
        expect_any_instance_of(Conjur::API).to \
            receive(:find_groups).with(gidnumber: 12_345).and_return search_result
        expect { invoke }.to write(JSON.pretty_generate(search_result))
      end
    end
  end

  describe_command "group:members:add group user:alice" do
    it "adds the role to the group" do
      expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: nil
      }.merge(cert_store_options))
      invoke
    end
  end

  describe_command "group:members:add -a group user:alice" do
    it "adds the role to the group with admin option" do
      expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: true }
      }.merge(cert_store_options))
      invoke
    end
  end
  describe_command "group:members:add -a group alice" do
    it "assumes that a nake member name is a user" do
     expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: true }
      }.merge(cert_store_options))
      invoke
    end
  end

  describe_command "group:members:add -r group alice" do
    it "revokes the admin rights" do
       expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: "https://authz.example.com/the-account/roles/group/group/?members&member=user:alice",
        headers: {},
        payload: { admin_option: false }
       }.merge(cert_store_options))
      invoke
    end
  end
end
