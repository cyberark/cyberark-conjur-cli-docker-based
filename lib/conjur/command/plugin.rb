#
# Copyright (C) 2015 Conjur Inc
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

require 'rubygems'
require 'rubygems/commands/install_command'
require 'rubygems/commands/uninstall_command'
require 'yaml'
require 'fileutils'

require 'conjur/command'

class Conjur::Command::Plugin < Conjur::Command
  def self.assert_empty(args)
    exit_now! 'Received extra command arguments' unless args.empty?
  end

  desc 'Manage plugins'
  command :plugin do |cmd|
    cmd.desc 'List installed plugins'
    cmd.command :list do |c|
      c.action do |_, _, args|
        self.assert_empty(args)
        Conjur::Config.plugins.each do |p|
          begin
            gem = Gem::Specification.find_by_name "conjur-asset-#{p}"
            puts "#{p} (#{gem.version})"
          rescue Gem::LoadError
            nil
          end
        end
      end
    end

    cmd.desc 'Install a plugin'
    cmd.arg_name 'PLUGIN'
    cmd.command :install do |c|
      c.arg_name 'version'
      c.desc 'Version of the plugin to install'
      c.flag [:v, :version], :default_value => Gem::Requirement.default

      c.action do |_, options, args|
        install_plugin(require_arg(args, 'PLUGIN'), options[:version])
      end
    end

    cmd.desc 'Uninstall a plugin'
    cmd.arg_name 'PLUGIN'
    cmd.command :uninstall do |c|
      c.action do |_, _, args|
        name = require_arg(args, 'PLUGIN')
        uninstall_plugin(name)
      end
    end

    cmd.desc "Show a plugin's details"
    cmd.arg_name 'PLUGIN'
    cmd.command :show do |c|
      c.action do |_, _, args|
        name = require_arg(args, 'PLUGIN')
        begin
          gem = Gem::Specification.find_by_name "conjur-asset-#{name}"
          puts "Name: #{name}"
          puts "Description: #{gem.summary}"
          puts "Gem: #{gem.name}"
          puts "Version: #{gem.version}"
        rescue Gem::LoadError
          puts "Plugin '#{name}' is not installed"
        end
      end
    end
  end
end

def install_plugin(name, version)
  uninstall_plugin(name) rescue Exception

  gem_name = name.start_with?('conjur-asset-') ? name : "conjur-asset-#{name}"

  cmd = Gem::Commands::InstallCommand.new
  cmd.handle_options ['--no-ri', '--no-rdoc', gem_name, '--version', "#{version}"]

  begin
    cmd.execute
  rescue Gem::SystemExitException => e
    if e.exit_code != 0
      raise e
    end
  end

  modify_plugin_list('add', name)
end

def uninstall_plugin(name)
  if Conjur::Config.plugins.include?(name)
    gem_name = name.start_with?('conjur-asset-') ? name : "conjur-asset-#{name}"

    cmd = Gem::Commands::UninstallCommand.new
    cmd.handle_options ['-x', '-I', '-a', gem_name]
    cmd.execute

    modify_plugin_list('remove', name)
  end
end

def modify_plugin_list(op, plugin_name)
  config_exists = false
  Conjur::Config.plugin_config_files.each do |f|
    if !File.file?(f)
      FileUtils.touch(f)
    end

    config = YAML.load(IO.read(f)).stringify_keys rescue {}
    config['plugins'] ||= []
    config['plugins'] += [plugin_name] if op == 'add'
    config['plugins'] -= [plugin_name] if op == 'remove'
    config['plugins'].uniq!

    File.write(f, YAML.dump(config))
  end
end
