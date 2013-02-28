module Conjur
  class Config
    @@attributes = {}
    
    class << self
      def inspect
        @@attributes.inspect
      end
      
      def plugins
        plugins = @@attributes['plugins']
        plugins.is_a?(Array) ? plugins : plugins.split(',')
      end
      
      def merge(a)
        a = {} unless a
        @@attributes.merge!(a)
      end
      
      def [](key)
        @@attributes[key.to_s]
      end
    end
  end
end