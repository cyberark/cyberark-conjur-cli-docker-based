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

      def full_resource_id id
        parts = id.split(':') unless id.nil? 
        if id.to_s.empty? or parts.size<2 
          raise "Id should consists of minimum two parts (passed value: #{id})"
        end
        if parts.size==2
          return [conjur_account, parts].flatten.join(":")
        end
        return id
      end

      def parse_full_resource_id id
        id_parts = id.split(':')
        account=id_parts[0]
        kind = id_parts[1]
        resource_id=id_parts[2,id_parts.size].join(":")
        resource_id=nil if resource_id.to_s.empty? 
        return [account, kind, resource_id]
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
