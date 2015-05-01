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
      def clear
        @@attributes = {}
      end

      def user_config_files
        if ENV['CONJURRC']
          return ENV['CONJURRC']
        else
          homefile = File.expand_path "~/.conjurrc"
          pwdfile = File.expand_path ".conjurrc"
          if homefile != pwdfile && File.file?(pwdfile)
            $stderr.puts "WARNING: .conjurrc file from current directory is " +
                "used. This behaviour is deprecated. Use ENV['CONJURRC'] to " +
                "explicitly define custom configuration file if needed"
          end
          [ homefile, pwdfile ]
        end
      end

      def default_config_files
        ['/etc/conjur.conf', user_config_files].flatten.uniq
      end

      def load(config_files = default_config_files)
        require 'yaml'
        require 'conjur/log'

        config_files.each do |f|
          if File.file?(f)
            if Conjur.log
              Conjur.log << "Loading #{f}\n"
            end
            config = YAML.load(IO.read(f)).stringify_keys rescue {}
            if config['cert_file']
              config['cert_file'] = File.expand_path(config['cert_file'], File.dirname(f))
            end
            Conjur::Config.merge config
          end
        end
      end


      def apply
        require 'conjur/configuration'

        keys = Config.keys.dup
        keys.delete(:plugins)

        cfg = Conjur.configuration
        keys.each do |k|
          if Conjur.configuration.respond_to?("#{k}_env_var") && (env_var = Conjur.configuration.send("#{k}_env_var")) && (v = ENV[env_var])
            if Conjur.log
              Conjur.log << "Not overriding environment setting #{k}=#{v}\n"
            end
            next
          end
          value = Config[k]
          cfg.set k, value if value
        end

        if Conjur.log
          require 'conjur/api'
          host = begin
            Conjur::Authn::API.host
          rescue RuntimeError
            nil
          end
          if host
            Conjur.log << "Using authn host #{Conjur::Authn::API.host}\n"
          end
        end

        Conjur.config.apply_cert_config!
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

      def member? key
        @@attributes.member?(key) || @@attributes.member?(alternate_key(key))
      end

      def alternate_key key
        case key
          when String then key.to_sym
          when Symbol then key.to_s
          else key
        end
      end
    end
  end
end
