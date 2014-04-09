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

class Conjur::Command::Assets < Conjur::Command
  self.prefix = :asset

  desc "Create an asset"
  arg_name "kind:id"
  command :create do |c|
    def c.nodoc; true end
    acting_as_option(c)
    
    c.action do |global_options, options, args|
      # NOTE: no generic functions there, as :id is optional
      kind, id = require_arg(args, 'kind:id').split(':')
      id = nil if id.blank?
      kind.gsub!('-', '_')

 
      m = "create_#{kind}"
      record = if [ 1, -1 ].member?(api.method(m).arity)
        if id
          options[:id] = id
        end
        api.send(m, options)
      else
        unless id
          raise "for kind #{kind} id should be specified explicitly after colon"
        end
        api.send(m, id, options)
      end
      display(record, options)
    end
  end
  
  desc "Show an asset"
  arg_name "id"
  command :show do |c|
    def c.nodoc; true end
    c.action do |global_options,options,args|
      kind, id = get_kind_and_id_from_args(args, 'id')
      display api.send(kind, id).attributes
    end
  end

  desc "Checks for the existance of an asset"
  arg_name "id"
  command :exists do |c|
    def c.nodoc; true end
    c.action do |global_options,options,args|
      kind, id = get_kind_and_id_from_args(args, 'id')
      puts api.send(kind, id).exists?
    end
  end

  desc "List an asset"
  arg_name "kind"
  command :list do |c|
    def c.nodoc; true end
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind").gsub('-', '_')
      if api.respond_to?(kind.pluralize)
        api.send(kind.pluralize)
      else
        api.resources(kind: kind)
      end.each do |e|
        display(e, options)
      end
    end
  end

  desc "Add a member to an asset"
  arg_name "id role-name member"
  command :"members:add" do |c|
    def c.nodoc; true end
    c.desc "Grant with admin option"
    c.flag [:a, :admin]

    c.action do |global_options, options, args|
      kind, id = get_kind_and_id_from_args(args, 'id')
      role_name = require_arg(args, 'role-name')
      member = require_arg(args, 'member')
      admin_option = !options.delete(:admin).nil?
      
      api.send(kind, id).add_member role_name, member, admin_option: admin_option
      puts "Membership granted"
    end
  end

  desc "Remove a member from an asset"
  arg_name "id role-name member"
  command :"members:remove" do |c|
    def c.nodoc; true end
    c.action do |global_options, options, args|
      kind, id = get_kind_and_id_from_args(args, 'id')
      role_name = require_arg(args, 'role-name')
      member = require_arg(args, 'member')
      api.send(kind, id).remove_member role_name, member
      puts "Membership revoked"
    end
  end
end
