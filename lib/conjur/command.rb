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
    end
  end
end
