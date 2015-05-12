#
# Copyright (C) 2013 Conjur Inc
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
require 'active_support/deprecation'
require 'active_support/dependencies/autoload'
require 'conjur/api'
require 'netrc'

Netrc.configure do |config|
  config[:allow_permissive_netrc_file] = true
end

module Conjur::Authn
  class NoCredentialsError < RuntimeError
    def initialize
      super "No Conjur credentials provided or found"
    end
  end
  
  autoload :API,      'conjur/authn-api'
  class << self
    def login(options = {})
      delete_credentials
      get_credentials(options)
    end
    
    def authenticate(options = {})
      require 'conjur/api'
      Conjur::API.authenticate(*get_credentials(options))
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      Conjur::Authn::API.host
    end
    
    def netrc
      @netrc ||= read_netrc
    end
    
    def read_netrc
      args = []
      if path = Conjur::Config[:netrc_path]
        args.unshift(path)
      else
        path = Netrc.default_path
      end
      fail_if_world_readable path
      Netrc.read(*args)
    end
    
    def get_credentials(options = {})
      @credentials ||= (env_credentials || read_credentials || fetch_credentials(options))
    end
    
    def env_credentials
      if (login = ENV['CONJUR_AUTHN_LOGIN']) && (api_key = ENV['CONJUR_AUTHN_API_KEY'])
        [ login, api_key ]
      else
        nil
      end
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials(options = {})
      ask_for_credentials(options)
      write_credentials
    end
    
    alias save_credentials fetch_credentials
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials(options = {})
      raise NoCredentialsError if options[:noask]

      # also use stderr here, because we might be prompting for a password as part
      # of a command like user:create that we'd want to send to a file.
      require 'highline'
      require 'conjur/api'

      hl = HighLine.new $stdin, $stderr
      
      user = options[:username] || hl.ask("Enter your username to log into Conjur: ")
      pass = options[:password] || hl.ask("Please enter #{options[:username] ? [ options[:username] , "'s" ].join : "your"} password (it will not be echoed): "){ |q| q.echo = false }
        
      api_key = if cas_server = options[:"cas-server"]
        Conjur::API.login_cas(user, pass, cas_server)
      else
        Conjur::API.login(user, pass)
      end
      @credentials = [user, api_key]
    end

    def connect(cls = nil, options = {})
      if cls.nil?
        require 'conjur/api'
        require 'conjur/base'
        cls = Conjur::API
      end
      cls.new_from_key(*get_credentials(options))
    end
    
    protected
    
    def fail_if_world_readable path
      if !windows? && File.world_readable?(path)
        fail "netrc (#{path}) shouldn't be world-readable" 
      end
    end
    
    # see http://stackoverflow.com/questions/4871309/what-is-the-correct-way-to-detect-if-ruby-is-running-on-windows
    def windows?
      RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
    end
  end
end
