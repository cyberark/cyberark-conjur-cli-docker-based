require 'spec_helper'

describe Conjur::Command::Resources, logged_in: true do

<<<<<<< HEAD
  describe_command "resource:check food bacon fry" do
    it "performs a permission check for the logged-in user" do
      api.should_receive(:resource).with("the-account:food:bacon").and_return bacon = double("the-account:food:bacon")
      bacon.should_receive(:permitted?).with("fry")
      
      invoke
    end
  end
  
  describe_command "resource:check -r test:the-role food bacon fry" do
    it "performs a permission check for a specified role" do
      api.should_receive(:role).with("test:the-role").and_return role = double("the-account:test:the-role")

      role.should_receive(:permitted?).with("food", "bacon", "fry")
      
      invoke
    end
  end
end
=======
  let (:full_resource_id) { [account, KIND, ID].join(":") }
  let (:resource_instance) { double(attributes: resource_attributes) }
  let (:resource_attributes) { { "some" => "attribute"} }

  before :each do
    api.stub(:resource).with(full_resource_id).and_return(resource_instance)
  end 

  def invoke_silently
    expect { invoke }.to write
  end

  shared_examples 'it displays resource attributes' do
    it "as JSON to stdout" do
      JSON::parse( expect { invoke }.to write ).should == resource_attributes
    end
  end

  shared_examples "it obtains resource by id" do
    it 'id is built from kind and id' do
      api.should_receive(:resource).with(%r{^[^:]*:#{KIND}:#{ID}$})
      invoke_silently
    end
    it 'uses default account as a prefix' do
      api.should_receive(:resource).with(%r{^#{account}:})
      invoke_silently
    end
  end

  describe_command "resource:create #{KIND}:#{ID}"  do
    before :each do
      resource_instance.stub(:create)
    end
    it "calls resource.create()" do
      resource_instance.should_receive(:create)
      invoke_silently
    end
    it_behaves_like "it obtains resource by id"
    it_behaves_like "it displays resource attributes"
  end

  describe_command "resource:show #{KIND}:#{ID}" do
    it_behaves_like "it obtains resource by id"
    it_behaves_like "it displays resource attributes"
  end

  describe_command "resource:exists #{KIND}:#{ID}" do
    before (:each) { 
      resource_instance.stub(:exists?).and_return("true")
    }
    it_behaves_like "it obtains resource by id" 
    it 'calls resource.exists?' do
      resource_instance.should_receive(:exists?)
      invoke_silently
    end
    context 'displays response of resource.exists? (true/false)' do
      # NOTE: a bit redundant, but will be helpful in 'documentation' context
      it 'true' do
        resource_instance.stub(:exists?).and_return("true")
        expect { invoke }.to write "true"
      end
      it 'false' do
        resource_instance.stub(:exists?).and_return("false")
        expect { invoke }.to write "false"
      end
    end
  end

  describe_command "resource:permit #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    before(:each) { resource_instance.stub(:permit).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.permit(#{PRIVILEGE}, #{ROLE})" do
      resource_instance.should_receive(:permit).with(PRIVILEGE, ROLE)
      invoke_silently
    end
    it {  expect { invoke }.to write "Permission granted" }
  end

  describe_command "resource:deny #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    before(:each) { resource_instance.stub(:deny).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.deny(#{PRIVILEGE},#{ROLE})" do
      resource_instance.should_receive(:deny).with(PRIVILEGE, ROLE)
      invoke_silently
    end
    it { expect { invoke }.to write "Permission revoked" }
  end

  describe_command "resource:check #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    let (:role_instance) { double() }
    let (:role_response) { "role response: true|false" }
    before(:each) { 
      api.stub(:role).and_return(role_instance)
      role_instance.stub(:permitted?).and_return(role_response)
    }
    it 'obtains role object by id' do
      api.should_receive(:role).with(ROLE)
      invoke_silently
    end
    it "calls role.permitted?(#{KIND}, #{ID}, #{PRIVILEGE})" do
      role_instance.should_receive(:permitted?).with(KIND,ID,PRIVILEGE)
      invoke_silently
    end
    it { expect { invoke }.to write role_response }
  end

  describe_command "resource:give #{KIND}:#{ID} #{OWNER}" do
    before(:each) { resource_instance.stub(:give_to).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.give_to(#{OWNER})" do
      resource_instance.should_receive(:give_to).with(OWNER)
      invoke_silently
    end
    it { expect { invoke }.to write "Role granted" }
  end

  describe_command "resource:permitted_roles #{KIND}:#{ID} #{PRIVILEGE}" do
    let(:roles_list) { %W[klaatu barada nikto] }
    before(:each) { 
      resource_instance.stub(:permitted_roles).and_return(roles_list) 
    }
    it_behaves_like "it obtains resource by id"
    it "calls resource.permitted_roles(#{PRIVILEGE}" do
      resource_instance.should_receive(:permitted_roles)
      invoke_silently
    end
    it "displays JSONised list of roles" do
      JSON.parse( expect { invoke }.to write ).should == roles_list
    end
  end
end
>>>>>>> Asset and resource commands no more use "kind" arg; it's evaluated from "id" instead
