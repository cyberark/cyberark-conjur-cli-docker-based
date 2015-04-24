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

class Conjur::Command::Plugin < Conjur::Command
  desc 'Manage plugins'
  command :plugin do |var|
    var.desc 'List installed plugins'
    var.command :list do |c|
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

    var.desc 'Install a plugin'
    var.arg_name 'name'
    var.command :install do |c|
      c.arg_name 'version'
      c.desc 'Version of the plugin to install'
      c.flag [:v, :version], :default_value => 'latest'

      c.action do |_, options, args|
        name = require_arg(args, 'name')
        gem_name = name.start_with?('conjur-asset-') ? name : "conjur-asset-#{name}"

        gem = Gem.latest_spec_for(gem_name)
        if gem.nil?
          exit_now! "gem #{gem_name} not found"
        end

        if options[:version] == 'latest'
          version = gem.version
        else
          version = options[:version]
        end

        puts "Installing #{gem.name}-#{version}"
        okay = system("#{gem_binary} install #{gem.name} -v #{version}")
        if okay
          #TODO: update conjurrc plugin list here
        end
      end
    end

    var.desc 'Uninstall a plugin'
    var.command :uninstall do |c|

    end

    var.desc "Show a plugin's details"
    var.arg_name 'name'
    var.command :show do |c|
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

def gem_binary
  if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
    "#{ENV['MY_RUBY_HOME']}/bin/gem"
  else
    "#{Gem.bindir}/gem"
  end
end