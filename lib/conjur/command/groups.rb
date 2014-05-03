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

class Conjur::Command::Groups < Conjur::Command
  self.prefix = :group
  
  desc "Create a new group"
  arg_name "id"
  command :create do |c|
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      id = require_arg(args, 'id')
      
      group = api.create_group(id, options)
      display(group, options)
    end
  end

  desc "List groups"
  command :list do |c|
    command_options_for_list c

    c.action do |global_options, options, args|
      command_impl_for_list global_options, options.merge(kind: "group"), args
    end
  end

  desc "Show a group"
  arg_name "id"
  command :show do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'id')
      display(api.group(id), options)
    end
  end

  desc "Lists all direct members of the group. The membership list is not recursively expanded."
  arg_name "group"
  command "members" do |c|
    c.desc "Verbose output"
    c.switch [:V,:verbose]

    c.action do |global_options,options,args|
      group = require_arg(args, 'group')
      
      display_members api.group(group).role.members, options
    end
  end

  desc "Add a new group member"
  arg_name "group member"
  command :"members:add" do |c|
    c.desc "Also grant the admin option"
    c.switch [:a, :admin]

    # perhaps this belongs to member:remove, but then either
    # it would be possible to grant membership with member:revoke,
    # or we would need two round-trips to authz
    c.desc "Revoke the grant option if it's granted"
    c.switch [:r, :'revoke-admin']
    
    c.action do |global_options,options,args|
      group = require_arg(args, 'group')
      member = require_arg(args, 'member')
      member = add_kind_to_id member, 'user'
      group = add_kind_to_id group, 'group'
      
      group = api.group(group)
      opts = nil
      message = "Membership granted"
      if options[:admin] then
        opts = { admin_option: true }
        message = "Adminship granted"
      elsif options[:'revoke-admin'] then
        opts = { admin_option: false }
        message = "Adminship revoked"
      end
      
      group.add_member member, opts
      puts message
    end
  end

  desc "Remove a group member"
  arg_name "group member"
  command :"members:remove" do |c|
    c.action do |global_options,options,args|
      group = require_arg(args, 'group')
      member = require_arg(args, 'member')
      
      api.group(group).remove_member member
      puts "Membership revoked"
    end
  end
end