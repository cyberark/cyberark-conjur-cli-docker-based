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
require 'openssl'
require 'socket'

class Conjur::Command::Init < Conjur::Command
  desc "Initialize the Conjur configuration"

  def self.write_file(filename, force, &block)
    if File.exists?(filename)
      unless force
        force = true if highline.ask("File #{filename} exists. Overwrite (yes/no): ").strip == "yes"
      end
      exit_now! "Not overwriting #{filename}" unless force
    end
    File.open(filename, 'w') do |f|
      yield f
    end
  end

  Conjur::CLI.command :init do |c|
    c.desc "URL of the Conjur service"
    c.arg_name 'URL'
    c.flag ["u", "url"]

    c.desc "Conjur organization account name"
    c.flag ["a", "account"]

    c.desc "Conjur SSL certificate (will be obtained from host unless provided by this option)"
    c.flag ["c", "certificate"]

    c.desc "File to write the configuration to"
    c.arg_name 'FILE'
    c.flag ["f", "file"]

    c.desc "Force overwrite of existing files"
    c.flag "force"

    c.action do |global_options,options,args|
      url = options[:url] || highline.ask("Enter the URL of your Conjur service: ").to_s
      url = URI.parse(url)

      Conjur.configuration.appliance_url = url.to_s

      if (certificate = options[:certificate]).blank? && url.scheme == "https"
        connect_hostname = [ url.host, url.port ].join(":")
        fingerprint, certificate = get_certificate connect_hostname

        puts
        puts fingerprint

        puts "\nPlease verify this certificate on the appliance using command:
              openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem\n\n"
        exit_now! "You decided not to trust the certificate" unless highline.ask("Trust this certificate (yes/no): ").strip == "yes"
      end
      
      configure_cert_store certificate
      
      account = options[:account] || highline.ask("Enter your organization account name: ").to_s

      exit_now! "account is required" if account.blank?

      config = {
        account: account,
        plugins: []
      }

      config[:appliance_url] = url.to_s

      config_file = File.expand_path('~/.conjurrc')

      if !options[:file].nil?
        config_file = File.expand_path(options[:file])
      elsif ENV['CONJURRC']
        config_file = File.expand_path(ENV['CONJURRC'])
      end

      unless certificate.blank?
        cert_file = File.join(File.dirname(config_file), "conjur-#{account}.pem")
        config[:cert_file] = cert_file
        write_file(cert_file, options[:force]) do |f|
          f.puts certificate
        end
        puts "Wrote certificate to #{cert_file}"
      end

      write_file(config_file, options[:force]) do |f|
        f.puts YAML.dump(config.stringify_keys)
      end

      puts "Wrote configuration to #{config_file}"
    end
  end
  
  def self.configure_cert_store certificate
    unless certificate.blank?
      cert_file = Tempfile.new("conjur_cert")
      File.write cert_file.path, certificate
      OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file cert_file.path
    end
  end
  
  def self.get_certificate connect_hostname
    include OpenSSL::SSL
    host, port = connect_hostname.split ':'
    port ||= 443

    sock = TCPSocket.new host, port.to_i
    ssock = SSLSocket.new sock
    ssock.connect
    chain = ssock.peer_cert_chain
    cert = chain.first
    fp = Digest::SHA1.digest cert.to_der

    # convert to hex, then split into bytes with :
    hexfp = (fp.unpack 'H*').first.upcase.scan(/../).join(':')

    ["SHA1 Fingerprint=#{hexfp}", chain.map(&:to_pem).join]
  rescue
    exit_now! "Unable to retrieve certificate from #{connect_hostname}"
  ensure
    ssock.close if ssock
    sock.close if sock
  end

  private

  def self.highline
    # isolated here so that highline is only loaded on demand
    require 'highline'
    @hl ||= HighLine.new $stdin, $stderr
  end
end
