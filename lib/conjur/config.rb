module Conjur
  class Config
    @@attributes = {}
    
    class << self
      def merge(a)
        a = {} unless a
        @@attributes.merge(a)
      end
      
      def [](key)
        @@attributes[key]
      end
    end
  end
end