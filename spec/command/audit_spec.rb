require 'spec_helper'

describe Conjur::Command::Audit, logged_in: true do
  let(:events) { [{'foo' => 'bar', 'zelda' => 'link', 'abc' => 'xyz'}, {'some' => 'other event'}] }

  def expect_api_call method, *args
    expect(api).to receive(method.to_sym).with(*args).and_return events
    #described_class.should_receive(:show_audit_events).with(events, an_instance_of(Hash))
  end

  def invoke_expecting_api_call method, *args
    expect_api_call method, *args
    invoke
  end

  def invoke_silently
    silence_stderr { invoke }
  end

  def self.describe_command_success cmd, method, *expected_args, &block
    describe_command cmd do
      it "calls api.#{method}(#{expected_args.map(&:inspect).join(',')})" do
        instance_eval(&block) if block
        invoke_expecting_api_call method, *expected_args
      end
    end
  end

  def self.it_calls_the_api command, api_method, *api_args, &block
    describe_command_success command, api_method, *api_args, &block
  end


  def self.it_fails command, *raise_error_args
    unless raise_error_args.empty? or ::Class === raise_error_args.first
      raise_error_args.unshift Exception
    end
    describe_command command do
      it "raises #{raise_error_args.map(&:inspect).join ' '}" do
        expect { invoke_silently }.to raise_error(*raise_error_args)
      end
    end
  end

  describe "audit:role" do
    context "with an argument" do
      context "of a full id" do
        it_calls_the_api "audit:role foo:bar:baz", :audit_role, 'foo:bar:baz', {}
      end
      context "without an account" do
        it_calls_the_api "audit:role bar:baz", :audit_role, 'the-conjur-account:bar:baz', {} do
          allow(Conjur::Command).to receive_messages(conjur_account: "the-conjur-account")
        end
      end
      context "without enough tokens" do
        it_fails "audit:role not-enough-tokens", RuntimeError, /expecting at least two tokens/i
      end
    end
  end

  describe "audit:resource" do
    context "without an argument" do
      it_fails "audit:resource", /missing parameter: resource/i
    end
    context "with an argument of" do
      context "a full id" do
        it_calls_the_api "audit:resource foo:bar:baz", :audit_resource, "foo:bar:baz", {}
      end
      context "an id with two tokens" do
        it_calls_the_api "audit:resource foo:bar", :audit_resource, "the-conjur-account:foo:bar", {} do
          allow(Conjur::Command).to receive_messages(conjur_account: "the-conjur-account")
        end
      end
      context "an id with one token" do
        it_fails "audit:resource foo", /expecting at least two tokens/i
      end
    end
  end
  
  describe "audit:all" do
    it_calls_the_api "audit:all", :audit, {}
  end

  describe "output formatting:" do
    include_context "default audit behavior"
    
    before {
      allow(api).to receive(:audit_event_feed).and_yield([audit_event])
    }

    describe_command "audit all" do
      let(:audit_event) { default_audit_event }
      it 'prints full JSON retrieved from API' do
        expect { invoke }.to write( JSON.pretty_generate(audit_event)  )
      end
    end

    describe_command "audit all -s" do
      let(:common_prefix) { "[#{default_audit_event["timestamp"]}] #{default_audit_event["user"]}" }
      let(:audit_event) { test_event }
      shared_examples_for "it supports standard prefix:" do
        describe "if acting_as is the same as user" do
          let(:audit_event) { test_event.tap { |e| e["acting_as"]=e["user"] } }
          it "prints default prefix" do
            expect { invoke }.to write(common_prefix)
          end
          it "does not print 'acting_as' statement" do
            expect { invoke }.to_not write(common_prefix+" (as ")
          end
        end

        describe "if acting_as is different from user" do
          it 'prints default prefix followed by (acting as..) statement' do
            expect { invoke }.to write(common_prefix+" (as #{audit_event['acting_as']})")
          end
        end
      end

      shared_examples_for "it recognizes error messages:" do
        describe "if :error is not empty" do
          let(:audit_event) { test_event.merge("error"=>"everything's down") }
          it 'appends (failed with...) statement' do
            expect { invoke }.to write(" (failed with everything's down)")
          end
        end
        describe "if :error is empty" do
          it 'does not print "failed with" statement' do
            expect { invoke }.not_to write(" (failed with ")
          end
        end
        
      end       

      describe "(unknown kind:action)" do
        let(:test_event) { default_audit_event }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'unknown event: <kind>:<action>'" do
          expect { invoke }.to write(" unknown event: some_asset:some_action!")
        end
      end

      describe "(resource:check)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource",
                                                      "action"=>"check", 
                                                      "privilege"=>"fry", 
                                                      "resource"=>"food:bacon",
                                                      "allowed" => "false" 
                                                     ) 
                          }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'checked that they...'" do
          expect { invoke }.to write(" checked that they can fry food:bacon (false)")
        end
      
      end

      describe "(resource:create)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "create",
                                                      "resource" => "food:bacon", 
                                                      "owner" => "user:cook" 
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'created resource ... owned by ... '" do
          expect { invoke }.to write(" created resource food:bacon owned by user:cook")
        end
      end

      describe "(resource:update)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "update",
                                                      "resource" => "food:bacon", 
                                                      "owner" => "user:cook" 
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'gave .. to .. '" do
          expect { invoke }.to write(" gave food:bacon to user:cook")
        end
      end
 
      describe "(resource:destroy)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "destroy",
                                                      "resource" => "food:bacon"
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'destroyed resource ... '" do
          expect { invoke }.to write(" destroyed resource food:bacon")
        end
      end
      
      describe "(resource:permit)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "permit",
                                                     "resource" => "food:bacon",
                                                     "privilege" => "fry",
                                                     "grantee" => "user:cook"
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'permitted .. to .. (grant option: .. ) '" do
          expect { invoke }.to write(" permitted user:cook to fry food:bacon (grant option: false)")
        end
      end
      
      describe "(resource:deny)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "deny",
                                                     "resource" => "food:bacon",
                                                     "privilege" => "fry",
                                                     "grantee" => "user:cook"
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'denied .. from .. on ..'" do
          expect { invoke }.to write(" denied fry from user:cook on food:bacon")
        end
      end

      describe "(resource:permitted_roles)" do
        let(:test_event) { default_audit_event.merge("kind"=>"resource", "action" => "permitted_roles",
                                                     "resource" => "food:bacon",
                                                     "privilege" => "fry"
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'listed roles permitted to .. on ..'" do
          expect { invoke }.to write(" listed roles permitted to fry on food:bacon")
        end
      end

      describe "(role:check)" do
        let(:options_set) { 
          {
             "kind"=>"role", "action" => "check",
             "resource" => "food:bacon",
             "privilege" => "fry",
             "allowed" => "false"
          }
        }
        describe 'on themselves' do
          let(:test_event) { default_audit_event.merge(options_set).merge("role" => default_audit_event["user"]) }
          it_behaves_like "it supports standard prefix:" 
          it_behaves_like "it recognizes error messages:"
          it "prints 'checked that they...'" do
            expect { invoke }.to write(" checked that they can fry food:bacon (false)")
          end
        end
        describe 'on others' do
          let(:test_event) { default_audit_event.merge(options_set).merge("role" => "some:other:guy") }
          it_behaves_like "it supports standard prefix:" 
          it_behaves_like "it recognizes error messages:"
          it "prints 'checked that they...'" do
            expect { invoke }.to write(" checked that some:other:guy can fry food:bacon (false)")
          end
        end
      end

      describe "(role:grant)" do
        let(:options_set) { 
          {
             "kind"=>"role", "action" => "grant",
             "member" => "other:guy",
             "role" => "super:user"
          }
        }
        describe 'without admin option' do
          let(:test_event) { default_audit_event.merge(options_set) }
          it_behaves_like "it supports standard prefix:" 
          it_behaves_like "it recognizes error messages:"
          it "prints 'granted role .. to .. without admin'" do
            expect { invoke }.to write(" granted role super:user to other:guy without admin")
          end
        end
        describe 'with admin option' do
          let(:test_event) { default_audit_event.merge(options_set).merge("admin_option" => true) }
          it_behaves_like "it supports standard prefix:" 
          it_behaves_like "it recognizes error messages:"
          it "prints 'granted role .. to .. with admin'" do
            expect { invoke }.to write(" granted role super:user to other:guy with admin")
          end
        end
      end
    
      describe "(role:revoke)" do
        let(:test_event) { default_audit_event.merge("kind"=>"role", "action" => "revoke",
                                                     "role" => "super:user",
                                                     "member" => "other:guy"
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'revoked role .. from .." do
          expect { invoke }.to write(" revoked role super:user from other:guy")
        end
      end

      describe "(role:create)" do
        let(:test_event) { default_audit_event.merge("kind"=>"role", "action" => "create",
                                                     "role" => "super:user",
                                                    ) 
                         }
        it_behaves_like "it supports standard prefix:" 
        it_behaves_like "it recognizes error messages:"
        it "prints 'created role .. " do
          expect { invoke }.to write(" created role super:user")
        end
      end

      describe 'audit of ssh:sudo' do
        let(:ssh_event) { default_audit_event.merge('kind' => 'audit', 'facility' => 'ssh',  'action' => 'sudo', 'command' => '/bin/ls', 'system_user' => 'test_user', 'target_user' => 'root') }
        context 'when sudo successful' do
          let(:test_event) { ssh_event.merge('allowed' => true) }
          it 'prints <user> ran <command>' do
            expect { invoke }.to write(" test_user ran '/bin/ls' as root")
          end
        end

        context 'when sudo fails' do
          let(:test_event) { ssh_event.merge('allowed' => false) }
          
          it 'prints <user> attempted to run <command>' do
            expect { invoke }.to write(" test_user attempted to run '/bin/ls' as root")
          end
        end
      end
        
    end
  end

  describe "limit and offset" do
    let(:events) { (1 .. 5).map { |x| { event: x } } }
    before {
      allow(api).to receive(:audit_event_feed).and_yield(events)
    }

    describe_command "audit all" do 
      it "prints all the elements" do
        expect(expect { invoke }.to write).to eq(events.map {|e| JSON.pretty_generate(e)}.join("\n")+"\n")  
      end
    end

    describe_command "audit all -l 2" do  
      it "prints only <limit> elements" do
        expect(expect { invoke }.to write).to eq(events[0..1].map {|e| JSON.pretty_generate(e)}.join("\n")+"\n")  
      end
    end

    describe_command "audit all -o 2" do  
      it "skips <offset> elements" do
        expect(expect { invoke }.to write).to eq(events[2..4].map {|e| JSON.pretty_generate(e)}.join("\n")+"\n")   
      end
    end

    describe_command "audit all -o 2 -l 2" do
      it "skips <offset> elements and prints only <limit> of remaining part" do
        expect(expect { invoke }.to write).to eq(events[2..3].map {|e| JSON.pretty_generate(e)}.join("\n")+"\n")
      end
    end

  end

end
