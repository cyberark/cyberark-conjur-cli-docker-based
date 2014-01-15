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

class Conjur::Command::Roles < Conjur::Command
  self.prefix = :role
  
  desc "Create a new role"
  arg_name "role"
  command :create do |c|
    acting_as_option(c)

    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      role = api.role(id)
      
      if ownerid = options.delete(:ownerid)
        options[:acting_as] = ownerid
      end
      
      role.create(options)
      puts "Created #{role}"
    end
  end
  
  desc "Determines whether a role exists"
  arg_name "role"
  command :exists do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      role = api.role(id)
      puts role.exists?
    end
  end

  desc "Lists role memberships"
  arg_name "role"
  command :memberships do |c|
    c.action do |global_options,options,args|
      roleid = args.shift
      role = roleid.nil? && api.current_role || api.role(roleid)
      display role.all.map(&:roleid)
    end
  end

  desc "Lists all members of the role"
  arg_name "role"
  command :members do |c|
    c.desc "Verbose output"
    c.switch [:V,:verbose]
    
    c.action do |global_options,options,args|
      role = args.shift || api.user(api.username).roleid
      result = if options[:V]
        api.role(role).members.collect {|member|
          {
            member: member.member.roleid,
            grantor: member.grantor.roleid,
            admin_option: member.admin_option
          }
        }
      else
        api.role(role).members.map(&:member).map(&:roleid)
      end
      display result
    end
  end

  desc "Grant a role to another role. You must have admin permission on the granting role."
  arg_name "role member"
  command :grant_to do |c|
    c.desc "Whether to grant with admin option"
    c.switch [:a,:admin]
    
    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      member = require_arg(args, 'member')
      role = api.role(id)
      grant_options = {}
      grant_options[:admin_option] = true if options[:admin]
      role.grant_to member, grant_options
      puts "Role granted"
    end
  end

  desc "Revoke a role from another role."
  arg_name "role member"
  command :revoke_from do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      member = require_arg(args, 'member')
      role = api.role(id)
      role.revoke_from member
      puts "Role revoked"
    end
  end
end