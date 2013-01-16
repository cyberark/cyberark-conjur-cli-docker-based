require 'gli'
require 'conjur/config'

module Conjur
  class Cli
    extend GLI::App

    class << self
      def load_config
        file_names = [ File.join("/etc", "conjur.conf"), File.join(ENV['HOME'], ".conjur") ]
        if file = file_names.find{|fn| File.exists?(fn)}
          Conjur::Config.merge YAML.load(IO.read(file))
        else
          raise "No Conjur configuration file found in #{file_names.join(', ')}"
        end
      end
    end
            
    load_config
    
    commands_from 'conjur/command'
    
    (Conjur::Config['plugins']||{}).each do |plugin|
      require "conjur-cli-#{plugin}"
    end
    
    on_error do |exception|
      unless exception.is_a?(GLI::CustomExit)
        puts "#{exception.class.name}: #{exception.to_s}"
        puts exception.backtrace.map{|l| "  #{l}"}.join("\n")
      end
      true
    end
  end
end
