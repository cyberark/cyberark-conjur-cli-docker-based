require 'spec_helper'

describe Conjur::Command::Audit, logged_in: true do
  let(:events) { [{'foo' => 'bar', 'zelda' => 'link', 'abc' => 'xyz'}, {'some' => 'other event'}] }

  def expect_api_call method, *args
    api.should_receive(method.to_sym).with(*args).and_return events
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
          Conjur::Command.stub(conjur_account: "the-conjur-account")
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
          Conjur::Command.stub(conjur_account: "the-conjur-account")
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

  describe_command "audit:send '[{\"action\":\"login\",\"user\":\"alice\"},{\"action\":\"sudo\",\"user\":\"alice\"}]' " do
    it 'calls api.audit_send with provided parameter' do
      api.should_receive(:audit_send).with("'[{\"action\":\"login\",\"user\":\"alice\"},{\"action\":\"sudo\",\"user\":\"alice\"}]'")
      expect { invoke }.to write "Events sent successfully"
    end 

    it 'does not hide exceptions coming from API' do
      api.should_receive(:audit_send).and_return { raise ArgumentError }
      expect { invoke }.to raise_error(ArgumentError)
    end
  end


end
