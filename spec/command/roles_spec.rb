require 'spec_helper'

describe Conjur::Command::Roles, logged_in: true do

  describe "role:grant_to" do
    describe_command "role:grant_to test:a test:b" do
      it "grants the role without options" do
        expect_any_instance_of(Conjur::Role).to receive(:grant_to).with("test:b", {})
        invoke
      end
    end
    describe_command "role:grant_to --admin test:a test:b" do
      it "grants the role with admin option" do
        expect_any_instance_of(Conjur::Role).to receive(:grant_to).with("test:b", {admin_option: true})
        invoke
      end
    end
  end

  describe "role:create" do
    describe_command "role:create test:the-role" do
      it "creates the role with no options" do
        expect_any_instance_of(Conjur::Role).to receive(:create).with({})
        
        invoke
      end
    end
    describe_command "role:create --as-role test:foo test:the-role" do
      it "creates the role with acting_as option" do
        expect(api).to receive(:role).with("test:foo").and_return double("test:foo", exists?: true, roleid: "test:test:foo")
        expect(api).to receive(:role).with("test:the-role").and_return role = double("new-role", roleid: "test:the-role")
        expect(role).to receive(:create).with({acting_as: "test:test:foo"})
        
        expect { invoke }.to write("Created role test:the-role")
      end
    end
    describe_command "role:create --as-group the-group test:the-role" do
      it "creates the role with with acting_as option" do
        expect(api).to receive(:group).with("the-group").and_return group = double("the-group", roleid: "test:group:the-group")
        expect(api).to receive(:role).with(group.roleid).and_return double("group:the-group", exists?: true, roleid: "test:group:the-group")
        expect(api).to receive(:role).with("test:the-role").and_return role = double("new-role", roleid: "test:the-role")
        expect(role).to receive(:create).with({acting_as: "test:group:the-group"})
        
        expect { invoke }.to write("Created role test:the-role")
      end
    end
  end
  
  describe "role:members" do
    let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
    let(:all_role_grants) { 
      all_roles.map do |r| 
        Conjur::RoleGrant.new(api.role("foo:user:joerandom"), api.role(r), api.role("foo:user:admin"), false)
      end
    }
    let(:role) do
      double "the role", members: all_role_grants
    end
  
    before do
      allow(api).to receive(:role).and_call_original
      allow(api).to receive(:role).with(rolename).and_return role
    end

    context "when logged in as a user" do
      let(:username) { "joerandom" }
      let(:rolename) { "user:joerandom" }
      
      describe_command "role:members" do
        it "lists all roles" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end

      describe_command "role:members -V" do
        it "lists all roles verbosely" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_role_grants.map(&:to_h).map(&:stringify_keys))
        end
        describe "without RoleGrant.role field" do
          it "lists the roles verbosely" do
            all_role_grants.each do |rg|
              rg.instance_variable_set "@role", nil
            end
            expect(JSON::parse(expect { invoke }.to write)).to eq(all_role_grants.map(&:to_h).map(&:stringify_keys))
          end
        end
      end

      describe_command "role:members --count" do
        it "counts the roles" do
          expect(role).to receive(:members).with({count: true}).and_return(all_roles.size)
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles.size)
        end
      end

      describe_command "role:members -k hamster -s frontend -o 10 -l 10" do
        it "lists selected roles" do
          expect(role).to receive(:members).with({kind: 'hamster', search: 'frontend', offset: "10", limit: "10"}).and_return(all_role_grants)
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end

      describe_command "role:members -k hamster,giraffe" do
        it "lists selected roles" do
          expect(role).to receive(:members).with({kind: %w(hamster giraffe)}).and_return(all_role_grants)
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end

      describe_command "role:members -k hamster -k giraffe" do
        it "applies only the last 'kind' filter" do
          expect(role).to receive(:members).with({kind: 'giraffe'}).and_return(all_role_grants)
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end
  
      describe_command "role:members foo:bar" do
        let(:rolename) { 'foo:bar' }
        it "lists all roles of foo:bar" do
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
        end
      end
    end
  end

  describe "role:memberships" do
    let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
    let(:all_role_objects) { all_roles.map{|r| double r, roleid: r } }
    let(:role) do
      double "the role", all: all_role_objects
    end
  
    before do
      allow(api).to receive(:role).and_call_original
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

      describe_command "when empty" do
        let(:all_roles) { [] }
        describe_command "role:memberships" do
          it "prints an empty array" do
            expect(JSON::parse(expect { invoke }.to write)).to eq([])
          end
        end
      end

      describe_command "role:memberships" do
        it "hides system roles" do
          expect(role).to receive(:all).with({}).and_return([
            double(:role, roleid: "the-account:@:hamster")
          ])
          expect(JSON::parse(expect { invoke }.to write)).to eq([])
        end
      end

      describe_command "role:memberships --count" do
        it "counts the roles" do
          expect(role).to receive(:all).with({count: true}).and_return(all_roles.size)
          expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles.size)
        end
      end

      context "with full role grant info" do
        let(:all_role_grants) { 
          all_roles.map do |r| 
            Conjur::RoleGrant.new(api.role(r), api.role("foo:user:joerandom"), api.role("foo:user:admin"), false)
          end
        }
        before {
          expect(role).to receive(:all).with({recursive: false}).and_return(all_role_grants)
        }
        describe_command "role:memberships --no-recursive" do
          it "lists the roles" do
            expect(JSON::parse(expect { invoke }.to write)).to eq(all_roles)
          end
        end
        describe_command "role:memberships -V --no-recursive" do
          it "shows all the roles" do
            expect(JSON::parse(expect { invoke }.to write)).to eq(all_role_grants.map(&:to_h).map(&:stringify_keys))
          end
        end
      end
  
      describe_command "role:memberships -k hamster -s frontend -o 10 -l 10" do
        it "lists selected roles" do
          expect(role).to receive(:all).with({kind: 'hamster', search: 'frontend', offset: "10", limit: "10"}).and_return(all_role_objects)
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
