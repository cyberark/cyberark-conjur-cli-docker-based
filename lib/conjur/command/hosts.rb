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

class Conjur::Command::Hosts < Conjur::Command
  def self.host_layer_roles host
    host.role.all.select{|r| r.kind == "layer"}
  end
  
  desc "Manage hosts"
  command :host do |hosts|
    hosts.desc "Create a new host"
    hosts.arg_name "NAME"
    hosts.command :create do |c|
      c.arg_name "password"
      c.flag [:p,:password]

      c.desc "A comma-delimited list of CIDR addresses to restrict user to (optional)"
      c.flag [:cidr]

      acting_as_option(c)

      c.action do |global_options,options,args|
        id = args.shift

        unless id
          ActiveSupport::Deprecation.warn "id argument will be required in future releases"
        end

        cidr = format_cidr(options[:cidr])

        host_options = { }
        host_options[:id] = id if id
        host_options[:cidr] = cidr unless cidr.empty?

        display api.create_host(host_options), host_options
      end
    end

    hosts.desc "Show a host"
    hosts.arg_name "HOST"
    hosts.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'HOST')
        display(api.host(id), options)
      end
    end

    hosts.desc "Decommission a host"
    hosts.arg_name "HOST"
    hosts.command :retire do |c|
      retire_options c

      c.action do |global_options,options,args|
        id = require_arg(args, 'HOST')
        
        host = api.host(id)

        validate_retire_privileges host, options
        
        host_layer_roles(host).each do |layer|
          puts "Removing from layer #{layer.id}"
          api.layer(layer.id).remove_host host
        end

        retire_resource host
        retire_role host
        give_away_resource host, options
        
        puts "Host retired"
      end
    end

    hosts.desc "List hosts"
    hosts.command :list do |c|
      command_options_for_list c
      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "host"), args
      end
    end

    hosts.desc "Update a hosts's attributes"
    hosts.arg_name "HOST"
    hosts.command :update do |c|
      c.desc "A comma-delimited list of CIDR addresses to restrict host to (optional)"
      c.flag [:cidr]

      c.action do |global_options, options, args|
        id = require_arg(args, 'HOST')

        host = api.host(id)

        cidr = format_cidr(options[:cidr])

        host_options = { }
        host_options[:cidr] = cidr unless cidr.empty?

        host.update(host_options)
        puts "Host updated"
      end
    end

    hosts.desc "[Deprecated] Enroll a new host into conjur"
    hosts.arg_name "HOST"
    hosts.command :enroll do |c|
      hide_docs(c)
      c.action do |global_options, options, args|
        id = require_arg(args, 'HOST')
        enrollment_url = api.host(id).enrollment_url
        puts enrollment_url
        $stderr.puts "On the target host, please execute the following command:"
        $stderr.puts "curl -L #{enrollment_url} | bash"
      end
    end

    hosts.desc "List the layers to which the host belongs"
    hosts.arg_name "HOST"
    hosts.command :layers do |c|
      c.action do |global_options, options, args|
        id = require_arg(args, 'HOST')
        host = api.host(id)
        display host_layer_roles(host).map(&:identifier), options
      end
    end
  end

  def self.format_cidr(cidr)
    (cidr || '').split(',').each {|x| x.strip!}
  end
end
