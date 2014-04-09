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
require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Hosts < Conjur::Command
  self.prefix = :host

  desc "Create a new host"
  arg_name "id"
  command :create do |c|
    c.arg_name "password"
    c.flag [:p,:password]
    
    acting_as_option(c)

    c.action do |global_options,options,args|
      id = args.shift
      options[:id] = id if id

      unless id
        ActiveSupport::Deprecation.warn "id argument will be required in future releases"
      end
      
      display api.create_host(options), options
    end
  end
  
  desc "Show a host"
  arg_name "id"
  command :show do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'id')
      display(api.host(id), options)
    end
  end

  desc "List hosts"
  command :list do |c|
    command_options_for_list c

    c.action do |global_options, options, args|
      command_impl_for_list global_options, options.merge(kind: "host"), args
    end
  end
  
  desc "List the layers to which the host belongs"
  arg_name "id"
  command :layers do |c|
    c.action do |global_options, options, args|
      id = require_arg(args, 'id')
      display api.host(id).role.all.select{|r| r.kind == "layer"}.map(&:identifier), options
    end
  end
  
  desc "Enroll a new host into conjur"
  arg_name "host"
  command :enroll do |c|
    c.action do |global_options, options, args|
      id = require_arg(args, 'host')
      enrollment_url = api.host(id).enrollment_url
      puts enrollment_url
      $stderr.puts "On the target host, please execute the following command:"
      $stderr.puts "curl -L #{enrollment_url} | bash"
    end
  end
end