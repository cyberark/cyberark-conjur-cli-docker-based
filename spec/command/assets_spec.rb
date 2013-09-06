require 'spec_helper'

describe Conjur::Command::Assets, logged_in: true do

  let(:asset) {  double(attributes: asset_attributes ) }
  let(:asset_attributes) { {"some"=>"attributes" } }
  before(:each) { api.stub(KIND.to_sym).and_return(asset) }
  def invoke_silently
    expect { invoke }.to write
  end

  context "asset:create" do
    before(:each) { 
      api.stub(:method).with("create_#{KIND}").and_return(double(arity:1))
      api.stub("create_#{KIND}".to_sym).and_return(asset)
    }
    describe_command "asset:create #{KIND}:#{ID}" do
      it "calls api.create_#{KIND}(id:#{ID})" do
        api.should_receive("create_#{KIND}".to_sym).with(id: ID)
        invoke_silently
      end
      it "writes JSONised attributes to stdout" do
        JSON.parse( expect { invoke }.to write ).should == asset_attributes
      end
    end
    describe_command "asset:create #{KIND}" do
      it "calls api.create_#{KIND}({})" do
        api.should_receive("create_#{KIND}".to_sym).with({})
        invoke_silently
      end
      it "writes JSONised attributes to stdout" do
        JSON.parse( expect { invoke }.to write ).should == asset_attributes
      end
    end
  end

  describe_command "asset:show #{KIND}:#{ID}" do
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      api.should_receive(KIND.to_sym).with(ID)
      invoke_silently
    end
    it "writes JSONised attributes to stdout" do
      JSON.parse( expect { invoke }.to write ).should == asset_attributes
    end
  end

  describe_command "asset:exists #{KIND}:#{ID}" do
    let(:exists_response) { "exists? response" }
    before(:each) { asset.stub(:exists?).and_return(exists_response) }
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      api.should_receive(KIND.to_sym).with(ID)
      invoke_silently
    end
    it "calls asset.exists?" do
      asset.should_receive(:exists?)
      invoke_silently
    end
    it "writes response to stdout" do
      expect { invoke }.to write exists_response
    end
  end

  describe_command "asset:list #{KIND}" do
    let(:assets_names) { %W[klaatu barada nikto] }
    let(:assets_list) { 
      assets_names.map { |x| 
        double(attributes: { "id" => x } )
      }
    }
    before(:each) { api.stub("#{KIND}s".to_sym).and_return(assets_list) }

    it "calls api.#{KIND}s" do
      api.should_receive("#{KIND}s".to_sym)
      invoke_silently
    end
    it "for each asset from response displays it's attributes" do
      expect { invoke }.to write assets_names.
                                  map { |x| 
                                    JSON.pretty_generate(id:x)
                                  }.join("\n")
    end
  end

  shared_examples 'it obtains role via asset' do
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      api.should_receive(KIND.to_sym).with(ID)
      invoke_silently
    end
    it "account=asset.core_conjur_account" do
      asset.should_receive(:core_conjur_account)
      invoke_silently
    end
    it "kind=asset.resource_kind" do
      asset.should_receive(:resource_kind)
      invoke_silently
    end
    it "id=asset.resource_id" do
      asset.should_receive(:resource_id)
      invoke_silently
    end

    it "obtains role as #{ACCOUNT}:@:#{KIND}/#{ID}/#{ROLE}" do
      api.should_receive(:role).with("#{ACCOUNT}:@:#{KIND}/#{ID}/#{ROLE}")
      invoke_silently
    end
  end

  shared_context "asset with role" do
    before(:each) {
      asset.stub(:core_conjur_account).and_return(ACCOUNT)
      asset.stub(:resource_kind).and_return(KIND)
      asset.stub(:resource_id).and_return(ID)
      api.stub(:role).and_return(role_instance)
    }
    let(:role_instance) { double(grant_to: true, revoke_from: true) }
  end

  describe_command "asset:members:add #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset with role"
    it_behaves_like "it obtains role via asset"
    it 'calls role.grant_to(member,...)' do
      role_instance.should_receive(:grant_to).with(MEMBER, anything)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership granted" }
  end
  
  describe_command "asset:members:remove #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset with role"
    it_behaves_like "it obtains role via asset"
    it 'calls role.revoke_from(member)' do
      role_instance.should_receive(:revoke_from).with(MEMBER)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership revoked" }
  end
end
