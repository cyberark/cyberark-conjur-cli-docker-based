require 'spec_helper'

describe Conjur::Command::Assets, logged_in: true do

  let(:asset) {  double(attributes: asset_attributes ) }
  let(:asset_attributes) { {"some"=>"attributes" } }
  before(:each) { allow(api).to receive(KIND.to_sym).and_return(asset) }
  def invoke_silently
    expect { invoke }.to write
  end

  context "asset:create" do
    before(:each) { 
      allow(api).to receive(:method).with("create_#{KIND}").and_return(double(arity:1))
      allow(api).to receive("create_#{KIND}".to_sym).and_return(asset)
    }
    describe_command "asset:create #{KIND}:#{ID}" do
      it "calls api.create_#{KIND}(id:#{ID})" do
        expect(api).to receive("create_#{KIND}".to_sym).with(id: ID)
        invoke_silently
      end
      it "writes JSONised attributes to stdout" do
        expect(JSON.parse( expect { invoke }.to write )).to eq(asset_attributes)
      end
    end
    describe_command "asset:create #{KIND}" do
      it "calls api.create_#{KIND}({})" do
        expect(api).to receive("create_#{KIND}".to_sym).with({})
        invoke_silently
      end
      it "writes JSONised attributes to stdout" do
        expect(JSON.parse( expect { invoke }.to write )).to eq(asset_attributes)
      end
    end
  end

  describe_command "asset:show #{KIND}:#{ID}" do
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      expect(api).to receive(KIND.to_sym).with(ID)
      invoke_silently
    end
    it "writes JSONised attributes to stdout" do
      expect(JSON.parse( expect { invoke }.to write )).to eq(asset_attributes)
    end
  end

  describe_command "asset:exists #{KIND}:#{ID}" do
    let(:exists_response) { "exists? response" }
    before(:each) { allow(asset).to receive(:exists?).and_return(exists_response) }
    it "obtains asset instance as api.#{KIND}(#{ID})" do
      expect(api).to receive(KIND.to_sym).with(ID)
      invoke_silently
    end
    it "calls asset.exists?" do
      expect(asset).to receive(:exists?)
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
    before(:each) { allow(api).to receive("#{KIND}s".to_sym).and_return(assets_list) }

    it "calls api.#{KIND}s" do
      expect(api).to receive("#{KIND}s".to_sym)
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
      expect(api).to receive(KIND.to_sym).with(ID)
      invoke_silently
    end
  end
  
  shared_context "asset instance" do
    before(:each) { 
      allow(api).to receive(KIND.to_sym).and_return(asset) 
      allow(asset).to receive(:add_member)
      allow(asset).to receive(:remove_member)
    }
  end

  describe_command "asset:members:add #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset instance"
    it_behaves_like "it obtains asset by kind and id"
    it 'calls role.grant_to(member,...)' do
      expect(asset).to receive(:add_member).with(ROLE, MEMBER, anything)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership granted" }
  end
  
  describe_command "asset:members:remove #{KIND}:#{ID} #{ROLE} #{MEMBER}" do
    include_context "asset instance"
    it_behaves_like "it obtains asset by kind and id"
    it 'calls role.revoke_from(member)' do
      expect(asset).to receive(:remove_member).with(ROLE, MEMBER)
      invoke_silently
    end
    it { expect { invoke }.to write "Membership revoked" }
  end
  
  describe_command "asset:provision #{PROVISIONER} #{KIND}:#{ID}" do
    include_context "asset instance"
    
    let(:exists?){ true }
    let(:provisioner) do
      Module.new do
        def provision options={}; end
      end
    end
    
    before do
      asset.stub(exists?: exists?)
      asset.stub(:provision)
      path = "conjur/provisioner/#{KIND}/#{PROVISIONER}"
      Conjur::Command.stub(:require).with(path).and_return true
      stub_const(path.classify,provisioner)
    end
    
    it_behaves_like "it obtains asset by kind and id"
    
    it "requires 'conjur/provisioner/#{KIND}/#{PROVISIONER}'" do
      Conjur::Command.should_receive(:require).with("conjur/provisioner/#{KIND}/#{PROVISIONER}")
      invoke_silently
    end
    
    it "calls #provision on the asset" do
      asset.should_receive(:provision)
      invoke_silently
    end
    
    it "extends the asset with the provisioner module" do
      asset.should_receive(:extend).with(provisioner)
      invoke_silently
    end
    
    context "when the specified asset does not exist" do
      let(:exists?){ false }
      it "the command fails without invoking #provision" do
        asset.should_not_receive :provision
        # Hmm, can't figure out a quick way to keep this from
        # writing to stderr during the tests :-(
        expect{ invoke_silently }.to raise_error
      end
    end
  end
  
end
