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
    
    ENV['CONJUR_ENV'] = Config[:env] if Config[:env]
    ENV['CONJUR_STACK'] = Config[:stack] if Config[:stack]
    
    commands_from 'conjur/command'
    
    (Conjur::Config['plugins']||{}).each do |plugin|
      require "conjur-cli-#{plugin}"
    end

    $stderr.puts "Using host #{Conjur::Authn::API.host}"
    
    on_error do |exception|
      unless exception.is_a?(GLI::CustomExit)
        puts "#{exception.class.name}: #{exception.to_s}"
        puts exception.backtrace.map{|l| "  #{l}"}.join("\n")
      end
      true
    end
  end
end
