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
module Conjur
  class Config
    @@attributes = {}
    
    class << self
      def load
        require 'yaml'
        [ File.join("/etc", "conjur.conf"), ( ENV['CONJURRC'] || File.join(ENV['HOME'], ".conjurrc") ) ].each do |f|
          if File.exists?(f)
            if Conjur.log
              Conjur.log << "Loading #{f}\n"
            end
            Conjur::Config.merge YAML.load(IO.read(f))
          end
        end
      end
      
      def apply
        ENV['CONJUR_ENV'] = Config[:env] || "production"
        ENV['CONJUR_STACK'] = Config[:stack] if Config[:stack]
        ENV['CONJUR_STACK'] ||= 'v4' if ENV['CONJUR_ENV'] == 'production'
        ENV['CONJUR_ACCOUNT'] = Config[:account] or raise "Missing configuration setting: account. Please set it in ~/.conjurrc"
  
        if Conjur.log
          Conjur.log << "Using host #{Conjur::Authn::API.host}\n"
        end
      end
      
      def inspect
        @@attributes.inspect
      end
      
      def plugins
        plugins = @@attributes['plugins']
        if plugins
          plugins.is_a?(Array) ? plugins : plugins.split(',')
        else
          []
        end
      end
      
      def merge(a)
        a = {} unless a
        @@attributes.merge!(a)
      end
      
      def [](key)
        @@attributes[key.to_s]
      end
    end
  end
end