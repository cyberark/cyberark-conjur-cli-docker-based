module Conjur
  class Command
    @@api = nil
    
    class << self
      attr_accessor :prefix
      
      def method_missing *a
        Conjur::CLI.send *a
      end
      
      def command name, *a, &block
        Conjur::CLI.command "#{prefix}:#{name}", *a, &block
      end
      
      def require_arg(args, name)
        args.shift or raise "Missing parameter: #{name}"
      end

      def api
        @@api ||= Conjur::Authn.connect
      end

      # injects account into 2-tokens id
      def full_resource_id id
        parts = id.split(':') unless id.nil? 
        if id.blank? or parts.size < 2
          raise "Expecting at least two tokens in #{id}"
        end
        if parts.size == 2
          id = [conjur_account, parts].flatten.join(":")
        end
        id
      end

      # removes accounts from 3+-tokens id, extracts kind
      def get_kind_and_id_from_args args, argname='id'
        flat_id = require_arg(args, argname)
        tokens=flat_id.split(':')
        raise "At least 2 tokens expected in #{flat_id}" if tokens.size<2
        tokens.shift if tokens.size>=3 # get rid of account
        kind=tokens.shift.gsub('-','_')
        [kind, tokens.join(':')]
      end

      def conjur_account
        Conjur::Core::API.conjur_account
      end
      
      def acting_as_option(command)
        command.arg_name 'Perform all actions as the specified Group'
        command.flag [:"as-group"]

        command.arg_name 'Perform all actions as the specified Role'
        command.flag [:"as-role"]
      end

      def display(obj, options = {})
        str = if obj.respond_to?(:attributes)
          JSON.pretty_generate obj.attributes
        elsif obj.respond_to?(:id)
          obj.id
        else
          JSON.pretty_generate obj
        end
        puts str
      end
    end
  end
end
