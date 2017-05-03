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
class Conjur::Command::Resources < Conjur::Command

  desc "Show an object"
  arg_name "RESOURCE"
  command :show do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "RESOURCE") )
      display api.resource(id).attributes
    end
  end
  
  desc "List objects"
  command :list do |c|
    c.desc "Filter by kind"
    c.flag [:k, :kind]

    command_options_for_list c

    c.action do |global_options, options, args|
      command_impl_for_list global_options, options, args
    end
  end

  desc "Check for a privilege on a resource"
  long_desc """
By default, the privilege is checked for the logged-in user.
Permission checks may be performed for other roles using the optional role argument.
When the role argument is used, either the logged-in user must either own the specified
resource or must have specified role in its memberships.
"""
  arg_name "RESOURCE PRIVILEGE"
  command :check do |c|
    c.desc "Role to check. By default, the current logged-in role is used"
    c.flag [:r,:role]

    c.action do |global_options,options,args|
      id = full_resource_id(require_arg(args, "RESOURCE"))
      privilege = args.shift or raise "Missing parameter: privilege"
      role = if options[:role]
        full_role_id(options[:role])
      else
        nil
      end
      puts api.resource(id).permitted? privilege, role: role
    end
  end

  desc "Manage resources"
  command :resource do |resource|
    resource.desc "Determines whether a resource exists"
    resource.arg_name "RESOURCE"
    resource.command :exists do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        puts api.resource(id).exists?
      end
    end
    
    resource.desc "List roles with a specified privilege on the resource"
    resource.arg_name "RESOURCE PRIVILEGE"
    resource.command :permitted_roles do |c|
      c.action do |global_options,options,args|
        id = full_resource_id(require_arg(args, "RESOURCE"))
        permission = require_arg(args, "PRIVILEGE")

        display api.resource(id).permitted_roles(permission)
      end
    end
  end
end
