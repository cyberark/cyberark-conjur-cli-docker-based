require 'highline'
require 'conjur/api'
require 'netrc'

module Conjur::Auth
  class << self
    def login
      p get_credentials
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      ENV['CONJUR_HOST'] || default_host
    end
    
    def default_host
      "localhost:3000"
    end
    
    def netrc
      @netrc ||= Netrc.read
    end
    
    def get_credentials
      @credentials ||= (read_credentials || fetch_credentials)
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials
      ask_for_credentials
      write_credentials
    end
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials
      hl = HighLine.new
      user = hl.ask "Enter your login to log into Conjur: "
      pass = hl.ask("Please enter your password (it will not be echoed): "){ |q| q.echo = false }
      @credentials = [user, get_api_key(user, pass)]
    end
    
    def get_api_key user, pass
      Conjur::API.get_key(user, pass)
    end
  end
end
