require 'gli'

module Conjur
  class Cli
    extend GLI::App
    
    Dir[File.dirname(__FILE__) + '/command/*.rb'].each {|file| require file }
  end
end
