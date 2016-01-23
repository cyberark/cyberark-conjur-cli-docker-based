require 'methadone'
require 'json'
require 'open-uri'
require 'conjur/version.rb'
require "conjur/conjurize/script"

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

      puts generate JSON.parse input
    end

    def self.generate host
      config = configuration host

      if options[:json]
        JSON.dump config
      else
        Script.generate config, options
      end
    end

    def self.apply_client_config
      require "conjur/cli"
      if conjur_config = options[:c]
        Conjur::Config.load [ conjur_config ]
      else
        Conjur::Config.load
      end
      Conjur::Config.apply
    end

    def self.configuration host
      apply_client_config

      host.merge \
        "account" => Conjur.configuration.account,
        "appliance_url" => Conjur.configuration.appliance_url,
        "certificate" => File.read(Conjur.configuration.cert_file).strip
    end

    on("-c CONJUR_CONFIG_FILE", "Overrides defaults (CONJURRC env var, ~/.conjurrc, /etc/conjur.conf).")
    on("-f HOST_JSON_FILE", "Host login and API key can be read from the output emitted from 'conjur host create'. This data can be obtained from stdin, or from a file.")
    on("--chef-executable PATH", "If specified, the designated chef-solo executable is used, otherwise Chef is installed on the target machine.")
    on("--ssh", "Indicates that Conjur SSH should be installed.")
    on("--sudo", "Indicates that all commands should be run via 'sudo'.")
    on("--conjur-cookbook-url NAME", "Overrides the default Chef cookbook URL for Conjur SSH.")
    on("--conjur-run-list RUNLIST", "Overrides the default Chef run list for Conjur SSH.")
    on \
      "--json",
      "Don't generate the script, instead just dump the configuration as JSON"
  end
end
