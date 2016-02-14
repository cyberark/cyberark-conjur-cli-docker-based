require "json"
require "open-uri"

class Conjur::Conjurize
  # generates a shell script to conjurize a host
  class Script
    COOKBOOK_RELEASES_URL =
      "https://api.github.com/repos/conjur-cookbooks/conjur/releases".freeze

    def self.tarballs_of_releases releases
      releases.map do |release|
        assets = release["assets"].select do |asset|
          asset["name"] =~ /conjur-v\d.\d.\d.tar.gz/
        end

        [release["name"], assets.map { |asset| asset["browser_download_url"] }]
      end
    end

    def self.latest_conjur_cookbook_release
      json = JSON.parse open(COOKBOOK_RELEASES_URL).read
      tarballs = tarballs_of_releases json

      latest = tarballs.first
      selected = tarballs.find { |release| !release[1].empty? }

      if selected != latest
        warn "WARNING: Latest cookbook release (#{latest.first}) does not "\
            "contain a valid package. Falling back to #{selected.first}."
      end

      selected[1].first
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
      @sudo ||= options["sudo"] ? ->(x) { "sudo -n #{x}" } : ->(x) { x }
    end

    # Generate a piece of shell to write to a file
    # @param path [String] absolute path to write to
    # @param content [String] contents to write
    # @option options [String, Fixnum] :mode mode to apply to the file
    def write_file path, content, options = {}
      [
        ((mode = options[:mode]) && set_mode(path, mode)),
        [sudo["tee"], path, "> /dev/null << EOF"].join(" "),
        content.strip,
        "EOF\n"
      ].compact.join("\n")
    end

    def set_mode path, mode
      mode = mode.to_s(8) if mode.respond_to? :to_int
      [
        [sudo["touch"], path].join(" "),
        [sudo["chmod"], mode, path].join(" ")
      ].join("\n")
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
      [
        "account: #{configuration['account']}",
        "appliance_url: #{configuration['appliance_url']}",
        "cert_file: /etc/conjur-#{configuration['account']}.pem",
        "netrc_path: /etc/conjur.identity",
        "plugins: []"
      ].join "\n"
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
        write_file("/etc/conjur.conf", Script.rc(configuration)),
        write_file(
          "/etc/conjur-#{configuration['account']}.pem",
          configuration["certificate"]
        ),
        write_file(
          "/etc/conjur.identity",
          Script.identity(configuration),
          mode: 0600
        )
      ].join "\n"
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
