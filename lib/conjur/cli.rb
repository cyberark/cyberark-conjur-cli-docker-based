#
# Copyright (C) 2013-2015 Conjur Inc.
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
require 'gli'
# need this to prevent an active support bug in some versions
require 'active_support'
require 'active_support/deprecation'
require 'xdg'
require 'fileutils'

# this makes mime/types gem load much faster by lazy loading
# mime types and caching them in binary form
ENV['RUBY_MIME_TYPES_LAZY_LOAD'] ||= 'true'
ENV['RUBY_MIME_TYPES_CACHE'] ||= (
  XDG['CACHE'].to_path.tap(&FileUtils.method(:mkdir_p)) + 'ruby-mime-types.cache'
).to_s

module Conjur
  autoload :Config,                 'conjur/config'
  autoload :Log,                    'conjur/log'
  autoload :IdentifierManipulation, 'conjur/identifier_manipulation'
  autoload :Authn,                  'conjur/authn'
  autoload :Command,                'conjur/command'
  autoload :DSL,                    'conjur/dsl/runner'
  autoload :DSLCommand,             'conjur/command/dsl_command'
  autoload :VERSION,                'conjur/version'

  module Audit
    autoload :Follower,             'conjur/audit/follower'
  end

  class CLI
    extend GLI::App

    class << self
      def load_config
        Conjur::Config.load
      end

      def apply_config
        Conjur::Config.apply
      end

      # Horible hack!
      # We want to support legacy commands like host:list, but we don't want to
      # do too much effort, and GLIs support for aliasing doesn't work out so well with
      # subcommands.
      def run args
       args = args.shift.split(':') + args unless args.empty?
        super args
      end

      def load_plugins
        # These used to be plugins but now they are in the core CLI
        plugins = Conjur::Config.plugins - %w(layer pubkeys)
        
        plugins.each do |plugin|
          begin
            filename = "conjur-asset-#{plugin}"
            require filename
          rescue LoadError => err
            warn "WARNING: #{err.message}\n" \
              "Could not load plugin '#{plugin}' specified in your config file.\n"\
              "Make sure you have the #{filename} gem installed."
          end
        end
      end

      # This makes our generate-commands script a little bit cleaner.  We can call this from that script
      # to ensure that commands for all plugins are loaded.
      def init!
        subcommand_option_handling :normal
        load_config
        apply_config
        load_plugins
        commands_from 'conjur/command'
      end
    end

    init!

    version Conjur::VERSION

    pre do |global,command,options,args|
      require 'conjur/api'

      if command.name_for_help.first == "init" and options.has_key?("account")
        ENV["CONJUR_ACCOUNT"]=options["account"]
      end
      apply_config
      require 'active_support/core_ext'
      options.delete_if{|k,v| v.blank?}
      options.symbolize_keys!

      if as_group = options.delete(:"as-group")
        group = Conjur::Command.api.group(as_group)
        role = Conjur::Command.api.role(group.roleid)
        exit_now!("Group '#{as_group}' doesn't exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = group.roleid
      end
      if as_role = options.delete(:"as-role")
        role = Conjur::Command.api.role(as_role)
        exit_now!("Role '#{as_role}' does not exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = role.roleid
      end
      
      true
    end
    
    on_error do |exception|
      require 'rest-client'
      require 'patches/conjur/error'

      run_default_handler = true
      if exception.is_a?(RestClient::Exception) && exception.response
        err = Conjur::Error.create exception.response.body
        if err
          $stderr.puts "error: " + err.message
          run_default_handler = false # suppress default error message
        else
          $stderr.puts exception.response.body
        end
      end

      run_default_handler
    end
  end
end
