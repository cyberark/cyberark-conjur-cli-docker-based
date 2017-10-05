#
# Copyright (C) 2013-2015 Conjur Inc
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

class Conjur::Command::Hosts < Conjur::Command
  def self.host_layer_roles host
    host.memberships.select{|r| r.kind == "layer"}
  end
  
  desc "Manage hosts"
  command :host do |hosts|

    hosts.desc "Rotate a host's API key"
    hosts.command :rotate_api_key do |c|
      c.desc "Login of host whose API key we want to rotate (default: logged-in host)"
      c.flag [:host, :h]
      c.action do |_global, options, _args|
        if options.include?(:host)
          host = options[:host]
          host_resourceid = full_resource_id("host:#{host}")

          unless api.resource(host_resourceid).exists?
            exit_now! "host '#{host}' not found"
          end

          # Prepend 'host/' if it wasn't passed in
          unless is_host_login?(host)
            host = 'host/' + host
          end

          # Make sure we're not trying to rotate our own key with the user flag.
          if api.username == host
            exit_now! 'To rotate the API key of the currently logged-in host, use this command without any flags or options'
          end

          puts api.resource(host_resourceid).rotate_api_key
        else
          username, password = Conjur::Authn.read_credentials
          # Make sure the current identity is a host
          unless is_host_login?(username)
            exit_now! "'#{username}' is not a valid host login, specify a host with the --host flag"
          end

          new_api_key = Conjur::API.rotate_api_key username, password
          # Show the new one before saving credentials so we don't lose it on failure.
          puts new_api_key
          Conjur::Authn.save_credentials username: username, password: new_api_key
        end
      end
    end

    hosts.desc "List the layers to which the host belongs"
    hosts.arg_name "HOST"
    hosts.command :layers do |c|
      c.action do |global_options, options, args|
        id = require_arg(args, 'HOST')
        host = api.resource(full_resource_id("host:#{id}"))
        display host_layer_roles(host).map(&:identifier), options
      end
    end
  end

  def self.format_cidr(cidr)
    case cidr
    when 'all'
      []
    when nil
      nil
    else
      cidr.split(',').each {|x| x.strip!}
    end
  end

  def self.is_host_login?(username)
    username.start_with?('host/')
  end
end
