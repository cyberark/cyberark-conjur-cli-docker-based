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

  shared_examples 'it obtains asset by kind and id' do
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      api.should_receive(KIND.to_sym).with(ID)
      invoke_silently
    end
  end
  
  shared_context "asset instance" do
    before(:each) { 
      api.stub(KIND.to_sym).and_return(asset) 
      asset.stub(:add_member)
      asset.stub(:remove_member)
    }
  end

  describe_command "asset:members:add #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset instance"
    it_behaves_like "it obtains asset by kind and id"
    it 'calls role.grant_to(member,...)' do
      asset.should_receive(:add_member).with(MEMBER, anything)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership granted" }
  end
  
  describe_command "asset:members:remove #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset instance"
    it_behaves_like "it obtains asset by kind and id"
    it 'calls role.revoke_from(member)' do
      asset.should_receive(:remove_member).with(MEMBER)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership revoked" }
  end
end
