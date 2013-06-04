require 'spec_helper'

describe Conjur::Command::Roles, logged_in: true do
  describe_command "role:memberships" do
    let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
    let(:role) do
      double "the role", all: all_roles.map{|r| double r, roleid: r }
    end

    before do
      api.stub(:role).with(rolename).and_return role
    end

    context "when logged in as a user" do
      let(:username) { "joerandom" }
      let(:rolename) { "the-account:user:joerandom" }

      it "lists all roles" do
        JSON::parse(expect { invoke }.to write).should == all_roles
      end
    end
  end
end
