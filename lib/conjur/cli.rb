require 'gli'

module Conjur
  class Cli
    extend GLI::App

    def load_config
      file_names = [ "conjur.conf", File.join(ENV['HOME'], "conjur.conf"), File.join("/etc", "conjur.conf"), File.join(ENV['HOME'], ".conjur"), File.join("/etc", "conjur") ]
      if file = file_names.find{|fn| File.exists?(fn)}
        Conjur::Config.attributes = YAML::load(ERB.new(IO.read(file)).result)
      else
        raise "No Conjur configuration file found in #{file_names.join(', ')}"
      end
    end
            
    load_config
    
    Dir[File.dirname(__FILE__) + '/command/*.rb'].each {|file| require file }
    
    (Conjur::Config['plugins']||{}).each do |plugin|
      require plugin.gsub('-', '_')
    end
  end
end
