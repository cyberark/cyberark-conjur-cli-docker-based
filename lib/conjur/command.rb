module Conjur
  class Command
    class << self
      attr_accessor :prefix
      
      def method_missing *a
        Conjur::Cli.send *a
      end
      
      def command name, *a, &block
        Conjur::Cli.command "#{prefix}:#{name}", *a, &block
      end
      
      def require_arg(args, name)
        args.shift or raise "Missing parameter: #{name}"
      end

      def api
        Conjur::Authn.connect
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
