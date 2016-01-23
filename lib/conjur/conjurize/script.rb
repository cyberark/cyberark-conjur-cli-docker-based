require "json"
require "open-uri"

class Conjur::Conjurize
  # generates a shell script to conjurize a host
  class Script
    COOKBOOK_RELEASES_URL =
      "https://api.github.com/repos/conjur-cookbooks/conjur/releases".freeze

    def self.latest_conjur_cookbook_release
      json = JSON.parse open(COOKBOOK_RELEASES_URL).read
      tarballs = json[0]["assets"].select do |asset|
        asset["name"] =~ /conjur-v\d.\d.\d.tar.gz/
      end
      tarballs.first["browser_download_url"]
    end

    HEADER = <<-HEADER.freeze
#!/bin/sh
set -e

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.
    HEADER

    def initialize options
      @options = options
    end

    attr_reader :options

    def sudo
      @sudo ||= options["sudo"] ? ->(x) { "sudo #{x}" } : ->(x) { x }
    end

    def write_file path, content
      "cat << EOF | #{sudo['tee']} #{path}\n" + content.strip + "\nEOF\n"
    end

    def self.generate configuration, options
      new(options).generate configuration
    end

    def install_chef?
      run_chef? && !options[:"chef-executable"]
    end

    def run_chef?
      options.values_at(:ssh, :"conjur-run-list").any?
    end

    def chef_executable
      options[:"chef-executable"] || "chef-solo"
    end

    def conjur_cookbook_url
      options[:"conjur-cookbook-url"] || Script.latest_conjur_cookbook_release
    end

    def conjur_run_list
      options[:"conjur-run-list"] || "conjur"
    end

    def chef_script
      @chef_script ||= [
        ("curl -L https://www.opscode.com/chef/install.sh | " + sudo["bash"] \
          if install_chef?),
        (sudo["#{chef_executable} -r #{conjur_cookbook_url} " \
            "-o #{conjur_run_list}"] if run_chef?)
      ].join "\n"
    end

    def self.rc configuration
      {
        account: configuration["account"],
        appliance_url: configuration["appliance_url"],
        cert_file: "/etc/conjur-#{configuration['account']}.pem",
        netrc_path: "/etc/conjur.identity",
        plugins: []
      }
    end

    def self.identity configuration
      """
        machine #{configuration['appliance_url']}/authn
        login host/#{configuration['id']}
        password #{configuration['api_key']}
      """
    end

    def configure_conjur configuration
      [
        write_file("/etc/conjur.conf", YAML.dump(Script.rc(configuration))),
        write_file(
          "/etc/conjur-#{configuration['account']}.pem",
          configuration["certificate"]
        ),
        write_file("/etc/conjur.identity", Script.identity(configuration))
      ].join
    end

    def generate configuration
      fail "No 'id' field in host JSON" unless configuration["id"]
      fail "No 'api_key' field in host JSON" unless configuration["api_key"]

      [
        HEADER,
        configure_conjur(configuration),
        chef_script
      ].join("\n")
    end
  end
end
