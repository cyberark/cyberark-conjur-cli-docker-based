require 'spec_helper'

describe Conjur::Command::Roles, logged_in: true do

  describe "role:create" do
    describe_command "role:create test:the-role" do
      it "creates the role with no options" do
        Conjur::Role.any_instance.should_receive(:create).with({})
        
        invoke
      end
    end
    describe_command "role:create --as-role test:foo test:the-role" do
      it "creates the role with acting_as option" do
        api.should_receive(:role).with("test:foo").and_return double("test:foo", exists?: true, roleid: "test:test:foo")
        api.should_receive(:role).with("test:the-role").and_return role = double("new-role")
        role.should_receive(:create).with({acting_as: "test:test:foo"})
        
        invoke
      end
    end
    describe_command "role:create --as-group the-group test:the-role" do
      it "creates the role with with acting_as option" do
        api.should_receive(:group).with("the-group").and_return group = double("the-group", roleid: "test:group:the-group")
        api.should_receive(:role).with(group.roleid).and_return double("group:the-group", exists?: true, roleid: "test:group:the-group")
        api.should_receive(:role).with("test:the-role").and_return role = double("new-role")
        role.should_receive(:create).with({acting_as: "test:group:the-group"})
        
        invoke
      end
    end
  end

  describe "role:memberships" do
    let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
    let(:role) do
      double "the role", all: all_roles.map{|r| double r, roleid: r }
    end
  
    before do
      api.stub(:role).with(rolename).and_return role
    end

    context "when logged in as a user" do
      let(:username) { "joerandom" }
      let(:rolename) { "user:joerandom" }
      
      describe_command "role:memberships" do
        it "lists all roles" do
          JSON::parse(expect { invoke }.to write).should == all_roles
        end
      end
  
      describe_command "role:memberships foo:bar" do
        let(:rolename) { 'foo:bar' }
        it "lists all roles of foo:bar" do
          JSON::parse(expect { invoke }.to write).should == all_roles
        end
      end
    end
  
    context "when logged in as a host" do
      let(:username) { "host/foobar" }
      let(:rolename) { "host:foobar" }
  
      describe_command "role:memberships" do
        it "lists all roles" do
          JSON::parse(expect { invoke }.to write).should == all_roles
        end
      end
    end
  end
end
