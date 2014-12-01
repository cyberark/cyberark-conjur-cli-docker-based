require 'json'
require 'methadone'

module Conjur
  class Conjurize
    include Methadone::Main
    include Methadone::CLILogging
  
    description "Generate a script to install Conjur onto a host"

    version Conjur::VERSION
  
    main do
      input = if input_file = options[:f]
        File.read(input_file)
      else
        STDIN.read
      end
      host = JSON.parse input
      
      login = host['id'] or raise "No 'id' field in host JSON"
      api_key = host['api_key'] or raise "No 'api_key' field in host JSON"
        
      require 'conjur/cli'
      if conjur_config = options[:c]
        Conjur::Config.load [ conjur_config ]
      else
        Conjur::Config.load
      end
      Conjur::Config.apply
        
      conjur_cookbook_url = conjur_run_list = nil
        
      conjur_run_list = options[:"conjur-run-list"]
      conjur_cookbook_url = options[:"conjur-cookbook-url"]
      chef_executable = options[:"chef-executable"]
      
      if options[:ssh]
        conjur_run_list ||= "conjur-ssh"
        conjur_cookbook_url ||= "https://github.com/conjur-cookbooks/conjur-ssh/releases/download/v1.2.0/conjur-ssh-v1.2.0.tar.gz"
      end
      
      sudo = lambda{|str| 
        [ options[:sudo] ? "sudo -n" : nil, str ].compact.join(" ")
      }
      
      header = <<-HEADER
#!/bin/sh
set -e
      HEADER
      configure_conjur = <<-CONFIGURE
#{sudo.call 'tee'} /etc/conjur.conf > /dev/null << CONJUR_CONF
account: #{Conjur.configuration.account}
appliance_url: #{Conjur.configuration.appliance_url}
cert_file: /etc/conjur-#{Conjur.configuration.account}.pem
netrc_path: /etc/conjur.identity
plugins: []
CONJUR_CONF

#{sudo.call 'tee'} /etc/conjur-#{Conjur.configuration.account}.pem > /dev/null << CONJUR_CERT
#{File.read(Conjur.configuration.cert_file).strip}
CONJUR_CERT

#{sudo.call 'tee'} /etc/conjur.identity > /dev/null << CONJUR_IDENTITY
machine #{Conjur.configuration.appliance_url}/authn
  login host/#{login}
  password #{api_key}
CONJUR_IDENTITY
#{sudo.call 'chmod'} 0600 /etc/conjur.identity
      CONFIGURE
      
      install_chef = if conjur_cookbook_url && !chef_executable
        %Q(curl -L https://www.opscode.com/chef/install.sh | #{sudo.call 'bash'})
      else
        nil
      end
      
      chef_executable ||= "chef-solo"

      run_chef = if conjur_cookbook_url
        %Q(#{sudo.call "#{chef_executable} -r #{conjur_cookbook_url} -o #{conjur_run_list}"})
      else
        nil
      end
      
      puts [ header, configure_conjur, install_chef, run_chef ].compact.join("\n")
    end
    
    on("-c CONJUR_CONFIG_FILE")
    on("-f HOST_JSON_FILE")
    on("--chef-executable PATH")
    on("--ssh")
    on("--sudo")
    on("--conjur-cookbook-url NAME")
    on("--conjur-run-list RUNLIST")
  end
end
