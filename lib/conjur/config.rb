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
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/indifferent_access'
module Conjur
  class Config
    @@attributes = {}
    
    class << self
      def load
        require 'yaml'
        [ File.join("/etc", "conjur.conf"), ( ENV['CONJURRC'] || File.join(ENV['HOME'], ".conjurrc") ), '.conjurrc' ].each do |f|
          if File.file?(f)
            if Conjur.log
              Conjur.log << "Loading #{f}\n"
            end
            Conjur::Config.merge YAML.load(IO.read(f))
          end
        end
      end
      
      def apply
        keys = Config.keys.dup
        keys.delete(:plugins)
        keys.each do |k|
          value = Config[k]
          Conjur.configuration.set k, value if value
        end
  
        if Conjur.log
          Conjur.log << "Using authn host #{Conjur::Authn::API.host}\n"
        end
        if Config[:cert_file]
          OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file Config[:cert_file]
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
        @@attributes.deep_merge!(a.stringify_keys)
      end
      
      def keys
        @@attributes.keys.map(&:to_sym)
      end
      
      def [](key)
        @@attributes[key.to_s]
      end
    end
  end
end
