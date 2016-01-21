#
# Copyright (C) 2016 Conjur Inc
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

class Conjur::Command::Server < Conjur::Command
  desc 'Show Conjur client and server versions'
  command :version do |v|
    v.action do |*_|
      puts "Conjur client version #{Conjur::VERSION}"
      show_server_version
    end
  end

  desc 'Server information'
  command :server do |server|
    server.desc 'Show service versions'
    server.command :version do |c|
      c.action do |*_|
        show_server_version
      end
    end

    server.desc 'Show general server information'
    server.command :info do |c|
      c.action do |*_|
        display Conjur::API.appliance_info
      end
    end

    server.desc 'Show server health information'
    server.command :health do |c|
      c.desc 'Show health information for a remote host, from the perspective of this server'
      c.flag :h, :host
      c.action do |_, options, _|
        display Conjur::API.appliance_health(options[:host])
      end
    end
  end

  class << self
    def show_server_version
      services = Conjur::API.appliance_info['services']
      appliance = services.delete 'appliance'
      puts "Conjur appliance version: #{appliance['version']}"
      puts 'Conjur service versions:'
      services.each do |name,info|
        puts "  #{name}: #{info['version']}"
      end
    end
  end
end