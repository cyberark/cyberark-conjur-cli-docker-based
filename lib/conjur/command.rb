module Conjur
  class Command
    class << self
      attr_accessor :prefix
      
      def command name, *a, &block
        Conjur::Cli.command "#{prefix}:#{name}", &block
      end
    end
  end
end
