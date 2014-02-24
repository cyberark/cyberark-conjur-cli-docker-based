#
# Copyright (C) 2014 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur/command'

class Conjur::Command::Init < Conjur::Command
  desc "Initialize the Conjur configuration"

  def self.write_file(filename, force, &block)
    if File.exists?(filename)
      unless force
        hl = HighLine.new $stdin, $stderr
        force = true if hl.ask("File #{filename} exists. Overwrite (yes/no): ").strip == "yes"
      end
      exit_now! "Not overwriting #{filename}" unless force
    end
    File.open(filename, 'w') do |f|
      yield f
    end
  end

  Conjur::CLI.command :init do |c|
    c.desc "Conjur account name (required)"
    c.flag ["a", "account"]
    
    c.desc "Hostname of the Conjur endpoint (required for virtual appliance)"
    c.flag ["h", "hostname"]

    c.desc "Conjur SSL certificate (will be obtained from host unless provided in parameter)"
    c.flag ["c", "certificate"]

    c.desc "File to write the configuration to"
    c.default_value File.join(ENV['HOME'], '.conjurrc')
    c.flag ["f","file"]
    
    c.desc "Force overwrite of existing files"
    c.flag "force"
    
    c.action do |global_options,options,args|
      hl = HighLine.new $stdin, $stderr

      account = options[:account] || hl.ask("Enter your account name: ")
      hostname = options[:hostname] || hl.ask("Enter the hostname of your Conjur endpoint: ")
      
      if (certificate = options[:certificate]).blank?
        unless hostname.blank?
          certificate = `echo | openssl s_client -connect #{hostname}:443  2>/dev/null | openssl x509 -fingerprint`
          exit_now! "Unable to retrieve certificate from #{hostname}" if certificate.blank?
          
          lines = certificate.split("\n")
          fingerprint = lines[0]
          certificate = lines[1..-1].join("\n")
          
          puts fingerprint

          exit_now! unless hl.ask("Trust this certificate (yes/no): ").strip == "yes"
        end
      end
      
      exit_now! "account is required" if account.blank?
      
      config = {
        account: account,
        plugins: %w(environment layer key-pair)
      }
      
      config[:appliance_url] = "https://#{hostname}/api" unless hostname.blank?
      
      unless certificate.blank?
        cert_file = File.join(File.dirname(options[:file]), "conjur-#{account}.pem")
        config[:cert_file] = cert_file
        write_file(cert_file, options[:force]) do |f|
          f.puts certificate
        end
        puts "Wrote certificate to #{cert_file}"
      end
      
      write_file(options[:file], options[:force]) do |f|
        f.puts YAML.dump(config.stringify_keys)
      end
      puts "Wrote configuration to #{options[:file]}"
    end
  end
end
