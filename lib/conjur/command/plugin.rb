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
require 'yaml'

GEMBIN = '/opt/conjur/embedded/bin/gem'

class Conjur::Command::Plugin < Conjur::Command
  desc 'Manage plugins'
  command :plugin do |cmd|
    # Only enable this plugin for omnibus-installed CLI
    hide_docs(cmd) unless File.file?(GEMBIN) or ENV['DEV']

    cmd.desc 'List installed plugins'
    cmd.command :list do |c|
      c.action do
        Conjur::Config.load
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
    cmd.arg_name 'name'
    cmd.command :install do |c|
      c.arg_name 'version'
      c.desc 'Version of the plugin to install'
      c.flag [:v, :version], :default_value => 'latest'

      c.action do |_, options, args|
        install_plugin(require_arg(args, 'name'), options[:version])
      end
    end

    cmd.desc 'Uninstall a plugin'
    cmd.arg_name 'name'
    cmd.command :uninstall do |c|
      c.action do |_, _, args|
        name = require_arg(args, 'name')
        uninstall_plugin(name)
      end
    end

    cmd.desc "Show a plugin's details"
    cmd.arg_name 'name'
    cmd.command :show do |c|
      c.action do |_, _, args|
        name = require_arg(args, 'name')
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
  gem_name = name.start_with?('conjur-asset-') ? name : "conjur-asset-#{name}"

  gem = Gem.latest_spec_for(gem_name)
  if gem.nil?
    exit_now! "gem #{gem_name} does not exist"
  end

  # Uninstall all versions of plugin to avoid multiple versions
  uninstall_plugin(name)

  version = gem.version if version == 'latest'
  okay = system("#{GEMBIN} install #{gem.name} -v #{version}")
  modify_plugin_list(name, 'add') if okay
end

def uninstall_plugin(name)
  if Conjur::Config.plugins.include?(name)
    gem_name = name.start_with?('conjur-asset-') ? name : "conjur-asset-#{name}"
    okay = system("#{GEMBIN} uninstall #{gem_name} --all")
    modify_plugin_list(name, 'remove') if okay
  else
    puts "Plugin #{name} is not installed"
  end
end

def modify_plugin_list(plugin_name, op)
  config_exists = false
  Conjur::Config.default_config_files.each do |f|
    if File.file?(f)
      config_exists = true
      config = YAML.load(IO.read(f)).stringify_keys rescue {}
      if op == 'add'
        unless config['plugins'].include?(plugin_name)
          config['plugins'] += [plugin_name]
        end
      elsif op == 'remove'
        if config['plugins'].include?(plugin_name)
          config['plugins'] -= [plugin_name]
        end
      end
      File.write(f, YAML.dump(config))
    end

    unless config_exists
      puts 'ERROR: No Conjur config found'
    end
  end
end
