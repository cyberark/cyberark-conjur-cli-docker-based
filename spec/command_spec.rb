require 'spec_helper'

describe Conjur::Command do
  describe "provides id conversion functions as a class methods" do
    describe "#full_resource_id(id)" do
      describe  "injects account into brief ids" do
        context "long id (3+ tokens)" do
          it "returns id as is" do
            expect(described_class.full_resource_id("a:b:c")).to eq("a:b:c")
          end
        end 
        context "brief id(2 tokens)" do
          before(:each) { allow(described_class).to receive(:conjur_account).and_return("current/acc") }
          it "injects current account as a prefix" do
            expect(described_class.full_resource_id("a:b")).to eq("current/acc:a:b")
          end
        end
        context "malformed id (no separators)" do
          it "breaks" do
            expect  { described_class.full_resource_id("a") }.to raise_error
            expect  { described_class.full_resource_id("nil") }.to raise_error
          end
        end
      end
    end
    describe "#get_kind_and_id_from_args(args, [argname])" do
      describe "extracts (kind, subid) from id" do
        def subject *args 
          described_class.get_kind_and_id_from_args(args) 
        end
        context "for brief ids(2 tokens)" do
          it "token#1=> kind (dashes replaced with undescrores), token#2=>id" do
            expect(subject("the-kind:the-id")).to eq(['the_kind','the-id'])
          end
        end
        context "for long ids(3+ tokens)" do    
          it "token #1=> ignored" do
            expect(subject("a:b:c:d")).not_to include('a')
          end
          it "token #2=> kind (dashes replaced with underscores)" do
            expect(subject("a:the-kind:c:d")[0]).to eq("the_kind")
          end
          it "extracts remaining part (starting from 3rd token) as an id" do
            expect(subject("a:b:c-token:d-token")[1]).to eq("c-token:d-token")
          end
        end 
        context "for too short input" do
          it "breaks" do
            expect { subject("a") }.to raise_error
          end
        end
        context "for empty parameters" do
          it "breaks" do
            expect { subject() }.to raise_error
          end
        end
      end
    end
  end

  describe "supports asset retirement" do
    let(:role){ double('Role', roleid: 'the-role-id')}
    let(:permission){ { 'role' => 'the-role-id', 'privilege' => 'read' } }
    let(:permissions){ [ permission ] }
    let(:resource){ double('Resource', deny: nil, attributes: {'permissions' => permissions}) }
    let(:resources){ [resource] }
    let(:api){ double('API') }
    let(:asset){ double('Asset', resources: resources, resource: resource) }
    describe "#retire_resource" do
      context "when given an object without a role" do
        it 'works' do
          expect(described_class).to receive(:api).and_return api
          expect(api).to receive(:role).with('the-role-id').and_return role
          described_class.retire_resource(asset)
        end
      end
    end
  end

end
