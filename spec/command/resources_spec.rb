require 'spec_helper'

describe Conjur::Command::Resources, logged_in: true do

  let (:full_resource_id) { [account, KIND, ID].join(":") }
  let (:resource_instance) { double(attributes: resource_attributes) }
  let (:resource_attributes) { { "some" => "attribute"} }

  before :each do
    allow(api).to receive(:resource).and_call_original
    allow(api).to receive(:resource).with(full_resource_id).and_return(resource_instance)
  end 

  def invoke_silently
    expect { invoke }.to write
  end

  shared_examples 'it displays resource attributes' do
    it "as JSON to stdout" do
      expect(JSON::parse( expect { invoke }.to write )).to eq(resource_attributes)
    end
  end

  shared_examples "it obtains resource by id" do
    it 'id is built from kind and id' do
      expect(api).to receive(:resource).with(%r{^[^:]*:#{KIND}:#{ID}$})
      invoke_silently
    end
    it 'uses default account as a prefix' do
      expect(api).to receive(:resource).with(%r{^#{account}:})
      invoke_silently
    end
  end

  describe_command "resource:create #{KIND}:#{ID}"  do
    before :each do
      allow(resource_instance).to receive(:create)
    end
    it "calls resource.create()" do
      expect(resource_instance).to receive(:create)
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
      allow(resource_instance).to receive(:exists?).and_return("true")
    }
    it_behaves_like "it obtains resource by id" 
    it 'calls resource.exists?' do
      expect(resource_instance).to receive(:exists?)
      invoke_silently
    end
    context 'displays response of resource.exists? (true/false)' do
      # NOTE: a bit redundant, but will be helpful in 'documentation' context
      it 'true' do
        allow(resource_instance).to receive(:exists?).and_return("true")
        expect { invoke }.to write "true"
      end
      it 'false' do
        allow(resource_instance).to receive(:exists?).and_return("false")
        expect { invoke }.to write "false"
      end
    end
  end

  describe_command "resource:permit #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    before(:each) { allow(resource_instance).to receive(:permit).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.permit(#{PRIVILEGE}, #{ROLE})" do
      expect(resource_instance).to receive(:permit).with(PRIVILEGE, ROLE)
      invoke_silently
    end
    it {  expect { invoke }.to write "Permission granted" }
  end

  describe_command "resource:permit -g #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    it 'calls resource.permit() with grant option' do
      expect(resource_instance).to receive(:permit).with(PRIVILEGE, ROLE, grant_option: true)
      invoke_silently
    end
  end

  describe_command "resource:deny #{KIND}:#{ID} #{ROLE} #{PRIVILEGE}" do
    before(:each) { allow(resource_instance).to receive(:deny).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.deny(#{PRIVILEGE},#{ROLE})" do
      expect(resource_instance).to receive(:deny).with(PRIVILEGE, ROLE)
      invoke_silently
    end
    it { expect { invoke }.to write "Permission revoked" }
  end

  describe_command "resource:check #{KIND}:#{ID} #{PRIVILEGE}" do
    it "performs a permission check for the logged-in user" do
      expect(api).to receive(:resource).with("the-account:#{KIND}:#{ID}").and_return bacon = double("the-account:#{KIND}:#{ID}")
      expect(bacon).to receive(:permitted?).with(PRIVILEGE)
      
      invoke
    end
  end

  describe_command "resource:check -r #{ROLE} #{KIND}:#{ID} #{PRIVILEGE}" do
    let (:role_instance) { double() }
    let (:role_response) { "role response: true|false" }
    let (:account) { ACCOUNT }
    before(:each) { 
      allow(api).to receive(:role).and_return(role_instance)
      allow(role_instance).to receive(:permitted?).and_return(role_response)
    }
    it 'obtains role object by id' do
      expect(api).to receive(:role).with(ROLE)
      invoke_silently
    end
    it "calls role.permitted?('#{ACCOUNT}:#{KIND}:#{ID}', #{PRIVILEGE})" do
      expect(role_instance).to receive(:permitted?).with([ACCOUNT,KIND,ID].join(":"),PRIVILEGE)
      invoke_silently
    end
    it { expect { invoke }.to write role_response }
  end

  describe_command "resource:give #{KIND}:#{ID} #{OWNER}" do
    before(:each) { allow(resource_instance).to receive(:give_to).and_return(true) }
    it_behaves_like "it obtains resource by id"
    it "calls resource.give_to(#{OWNER})" do
      expect(resource_instance).to receive(:give_to).with(OWNER)
      invoke_silently
    end
    it { expect { invoke }.to write "Ownership granted" }
  end

  context "list" do
    def make_resource(kind, identifier, attributes)
      authz_host = "http://conjur/authz"
      credentials = {}
      id = "the-account:#{kind}:#{identifier}"
      api.resource(id).tap do |resource|
        resource.attributes = attributes.merge(resourceid: id)
      end
    end
    let(:resources) {
      [
        make_resource("food", "bacon", {}),
        make_resource("food", "eggs", {})
      ]
    }
    let(:resource_ids) {
      [
        "the-account:food:bacon",
        "the-account:food:eggs"
      ]      
    }
    describe_command "resource:list" do
      it "displays JSONised list of resources" do
        expect(api).to receive(:resources).with({}).and_return(resources)
        expect(JSON.parse( expect { invoke }.to write )).to eq([
          {"resourceid"=>"the-account:food:bacon", "annotations"=>{}}, 
          {"resourceid"=>"the-account:food:eggs", "annotations"=>{}}
        ])
      end
    end
    describe_command "resource:list -i" do
      it "displays resource ids" do
        expect(api).to receive(:resources).with({}).and_return(resources)
        expect(JSON.parse( expect { invoke }.to write )).to eq(resource_ids)
      end
    end
    { search: "hamster", offset: 10, limit: 10 }.each do |k,v|
      describe_command "resource:list -i --#{k} #{v}" do
        it "displays the items" do
          expect(api).to receive(:resources).with({k => v.to_s}).and_return(resources)
          expect(JSON.parse( expect { invoke }.to write )).to eq(resource_ids)
        end
      end
    end
  end

  context "permitted roles" do
    let(:roles_list) { %W[klaatu barada nikto] }
    describe_command "resource:permitted_roles #{KIND}:#{ID} #{PRIVILEGE}" do
      before(:each) { 
        allow(resource_instance).to receive(:permitted_roles).and_return(roles_list) 
      }
      it_behaves_like "it obtains resource by id"
      it "calls resource.permitted_roles(#{PRIVILEGE}" do
        expect(resource_instance).to receive(:permitted_roles).with(PRIVILEGE, {})
        invoke_silently
      end
      it "displays JSONised list of roles" do
        expect(JSON.parse( expect { invoke }.to write )).to eq(roles_list)
      end
    end

    describe_command "resource:permitted_roles --count #{KIND}:#{ID} #{PRIVILEGE}" do
      before {
        expect(resource_instance).to receive(:permitted_roles).with(PRIVILEGE, count: true).
          and_return(12) 
      }
      it_behaves_like "it obtains resource by id"
      it "calls resource.permitted_roles(#{PRIVILEGE}" do
        invoke_silently
      end
      it "displays role count" do
        expect(JSON.parse( expect { invoke }.to write )).to eq(12)
      end
    end


    describe_command "resource:permitted_roles -s frontend #{KIND}:#{ID} #{PRIVILEGE}" do
      let(:roles_list) { %W[klaatu barada nikto] }
      before {
        expect(resource_instance).to receive(:permitted_roles).with(PRIVILEGE, search: "frontend").
          and_return(roles_list) 
      }
      it_behaves_like "it obtains resource by id"
      it "displays JSONised list of roles" do
        expect(JSON.parse( expect { invoke }.to write )).to eq(roles_list)
      end
    end
  end
  
  context "interactivity" do
    subject { Conjur::Command::Resources }
    describe_command 'resource:annotate -i #{KIND}:#{ID}' do
      it { 
        is_expected.to receive(:prompt_for_annotations) 
        invoke_silently
      }
    end
  end
end
