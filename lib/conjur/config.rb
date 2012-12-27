module Conjur
  class Config
    self.attributes = nil
    
    class << self
      def [](key)
        raise "Conjur::Config is not initialized" unless self.attributes
        self.attributes[key]
      end
    end
  end
end