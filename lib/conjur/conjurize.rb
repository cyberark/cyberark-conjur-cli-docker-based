require 'methadone'
require 'json'
require 'open-uri'
require 'conjur/version.rb'

def latest_conjur_ssh_release
  url = 'https://api.github.com/repos/conjur-cookbooks/conjur-ssh/releases'
  resp = open(url)
  json = JSON.parse(resp.read)
  latest = json[0]['assets'].select {|asset| asset['name'] =~ /conjur-ssh-v\d.\d.\d.tar.gz/}[0]
  latest['browser_download_url']
end

module Conjur
  class Conjurize
    include Methadone::Main
    include Methadone::CLILogging

    description <<-DESC
Generate a script to install Conjur onto a machine. "conjurize" is designed to be used
in a piped execution, along with "conjur host create" and "ssh". For example:

conjur host create myhost.example.com | tee host.json | conjurize --ssh | ssh myhost.example.com
DESC

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
        conjur_cookbook_url ||= latest_conjur_ssh_release()
      end

      sudo = lambda{|str|
        [ options[:sudo] ? "sudo -n" : nil, str ].compact.join(" ")
      }

      header = <<-HEADER
#!/bin/sh
set -e

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.
      HEADER

      # NOTE: change the identity file generation to use hostname
      # instead of URL after the new Conjur version (> 4.18.1) handling
      # that hits the cookbook
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

    on("-c CONJUR_CONFIG_FILE", "Overrides defaults (CONJURRC env var, ~/.conjurrc, /etc/conjur.conf).")
    on("-f HOST_JSON_FILE", "Host login and API key can be read from the output emitted from 'conjur host create'. This data can be obtained from stdin, or from a file.")
    on("--chef-executable PATH", "If specified, the designated chef-solo executable is used, otherwise Chef is installed on the target machine.")
    on("--ssh", "Indicates that Conjur SSH should be installed.")
    on("--sudo", "Indicates that all commands should be run via 'sudo'.")
    on("--conjur-cookbook-url NAME", "Overrides the default Chef cookbook URL for Conjur SSH.")
    on("--conjur-run-list RUNLIST", "Overrides the default Chef run list for Conjur SSH.")
  end
end
