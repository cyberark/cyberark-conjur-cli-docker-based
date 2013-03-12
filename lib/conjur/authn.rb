require 'highline'
require 'conjur/api'
require 'netrc'

module Conjur::Authn
  class << self
    def login(options = {})
      delete_credentials
      get_credentials(options)
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      Conjur::Authn::API.host
    end
    
    def netrc
      @netrc ||= Netrc.read
    end
    
    def get_credentials(options = {})
      @credentials ||= (read_credentials || fetch_credentials(options))
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials(options = {})
      ask_for_credentials(options)
      write_credentials
    end
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials(options = {})
      raise "No credentials provided or found" if options[:noask]
      
      hl = HighLine.new
      user = options[:username] || hl.ask("Enter your login to log into Conjur: ")
      pass = options[:password] || hl.ask("Please enter your password (it will not be echoed): "){ |q| q.echo = false }
      api_key = if cas_server = options[:"cas-server"]
        Conjur::API.login_cas(user, pass, cas_server)
      else
        Conjur::API.login(user, pass)
      end
      @credentials = [user, api_key]
    end
    
    def connect(cls = Conjur::API, options = {})
      cls.new_from_key(*get_credentials(options))
    end
  end
end
