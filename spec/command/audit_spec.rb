require 'spec_helper'

describe Conjur::Command::Audit, logged_in: true do
  let(:events) { [{'foo' => 'bar', 'zelda' => 'link', 'abc' => 'xyz'}, {'some' => 'other event'}] }

  def expect_api_call method, *args
    api.should_receive(method.to_sym).with(*args).and_return events
    described_class.should_receive(:show_audit_events).with(events, an_instance_of(Hash))
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
    accepts_pagination_params command, api_method, *api_args, &block
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

  def self.accepts_pagination_params cmd, api_method, *api_method_args, &block
    context "with valid pagination options" do
      expected_opts   = {limit: 12, offset: 2}
      api_method_args = case api_method_args.last
      when Hash
        api_method_args[0..-2] << api_method_args.last.merge(expected_opts)
      else
        api_method_args.dup << expected_opts
      end
      describe_command_success cmd + " --limit 12 --offset 2", api_method, *api_method_args, &block
    end
    context "with garbage pagination options" do
      it_fails cmd + " --limit hiythere", RuntimeError, /expected an integer for limit/i
      it_fails cmd + " --offset hiythere", RuntimeError, /expected an integer for offset/i
    end
  end

  describe "audit:role" do
    context "without an argument" do
      it_calls_the_api "audit:role", :audit_current_role, {}
    end
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
end