require 'spec_helper'

describe Conjur::Command::Roles, logged_in: true do
  describe "role:memberships" do
    let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
    let(:role) do
      double "the role", all: all_roles.map{|r| double r, roleid: r }
    end
  
    before do
      allow(api).to receive(:role).with(rolename).and_return role
    end

    context "when logged in as a user" do
      let(:username) { "joerandom" }
      let(:rolename) { "user:joerandom" }
      
      describe_command "role:memberships" do
        it "lists all roles" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end
  
      describe_command "role:memberships foo:bar" do
        let(:rolename) { 'foo:bar' }
        it "lists all roles of foo:bar" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end
    end
  
    context "when logged in as a host" do
      let(:username) { "host/foobar" }
      let(:rolename) { "host:foobar" }
  
      describe_command "role:memberships" do
        it "lists all roles" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end
    end
  end
  
  describe "role graph" do 
    let(:roles){ [] }
    let(:options){ { ancestors: true, descendants: true } }
    let(:extra_options){ {} }
    let(:role_graph_args){ [roles, options.merge(extra_options)] }
    let(:graph_edges){ [['a', 'b'], ['b', 'c']] }
    let(:graph){ Conjur::Graph.new graph_edges }
    def output
      JSON::parse(expect{invoke}.to write)
    end
    
    before do
      allow(api).to receive(:role_graph).with(*role_graph_args).and_return graph
    end
    
    describe_command "role graph foo bar" do
      let(:roles){ %w(foo bar) }
      it "outputs the graph as non-short json" do
        expect(output).to eq(graph.as_json)
      end
    end
    
    describe_command 'role graph --short foo' do
      let(:roles){ %w(foo) }
      it 'outputs the graph as short json' do
        expect(output).to eq(graph.as_json(true))
      end
    end
    
    describe_command 'role graph --no-ancestors foo' do
      let(:roles){ %w(foo) }
      let(:options){{descendants: true}}
      it "calls role_graph with the expected options and output" do
        expect(output).to eq(graph.as_json(false))
      end
    end
    
    describe 'output formats' do
      let(:formatted){ "formatted by #{format_method}" }
      let(:roles){ %w(foo) }
      before do

        expect_any_instance_of(Conjur::Graph).to receive(format_method).with(any_args).and_return formatted
      end
      
      def self.it_formats_the_graph_as method
        let(:format_method){ method }
        it "formats the graph with #{method}" do
          expect((expect{invoke}.to write).chomp).to eq(formatted)
        end
      end
      
      describe_command 'role graph -fdot foo' do
        it_formats_the_graph_as :to_dot
      end
    end

  end
end
