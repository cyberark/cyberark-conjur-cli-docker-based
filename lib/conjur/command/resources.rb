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

  desc "Manage resources"
  command :resource do |resource|

    resource.desc "Create a new resource"
    resource.arg_name "RESOURCE"
    resource.command :create do |c|
      acting_as_option(c)

      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        resource = api.resource(id)

        if ownerid = options.delete(:ownerid)
          options[:acting_as] = ownerid
        end

        resource.create(options)
        display resource.attributes
      end
    end

    resource.desc "Show a resource"
    resource.arg_name "RESOURCE"
    resource.command :show do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        display api.resource(id).attributes
      end
    end

    resource.desc "Determines whether a resource exists"
    resource.arg_name "RESOURCE"
    resource.command :exists do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        puts api.resource(id).exists?
      end
    end

    resource.desc "Give a privilege on a resource"
    resource.arg_name "RESOURCE ROLE PRIVILEGE"
    resource.command :permit do |c|
      c.desc "allow transfer to other roles"
      c.switch [:g, :grantable]
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        role = require_arg(args, "ROLE")
        privilege = require_arg(args, "PRIVILEGE")
        unless options[:g]
          api.resource(id).permit privilege, role
        else
          api.resource(id).permit privilege, role, grant_option: true
        end
        
        puts "Permission granted"
      end
    end

    resource.desc "Deny a privilege on a resource"
    resource.arg_name "RESOURCE ROLE PRIVILEGE"
    resource.command :deny do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        role = require_arg(args, "ROLE")
        privilege = require_arg(args, "PRIVILEGE")
        api.resource(id).deny privilege, role
        puts "Permission revoked"
      end
    end

    resource.desc "Check for a privilege on a resource"
    resource.long_desc """
  By default, the privilege is checked for the logged-in user.
  Permission checks may be performed for other roles using the optional role argument.
  When the role argument is used, either the logged-in user must either own the specified
  resource or be an admin of the specified role (i.e. be granted the specified role with grant option).
  """
    resource.arg_name "RESOURCE PRIVILEGE"
    resource.command :check do |c|
      c.desc "Role to check. By default, the current logged-in role is used"
      c.flag [:r,:role]

      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        privilege = args.shift or raise "Missing parameter: privilege"
        if role = options[:role]
          role = api.role(role)
          puts role.permitted? id, privilege
        else
          puts api.resource(id).permitted? privilege
        end
      end
    end

    resource.desc "Grant ownership on a resource to a new owner"
    resource.arg_name "RESOURCE USER"
    resource.command :give do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        owner = require_arg(args, "USER")
        api.resource(id).give_to owner
        puts "Ownership granted"
      end
    end

    resource.desc "List roles with a specified permission on the resource"
    resource.arg_name "RESOURCE PERMISSION"
    resource.command :permitted_roles do |c|
      c.action do |global_options,options,args|
        id = full_resource_id( require_arg(args, "RESOURCE") )
        permission = require_arg(args, "PERMISSION")
        display api.resource(id).permitted_roles(permission)
      end
    end

    resource.desc "Set an annotation on a resource"
    resource.arg_name "RESOURCE ANNOTATION value"
    resource.command :annotate do |c|
      interactive_option c
      
      c.action do |global_options, options, args|
        id = full_resource_id require_arg(args, 'RESOURCE')

        annotations = if options[:interactive]
          prompt_for_annotations
        else
          name = require_arg args, 'ANNOTATION'
          value = require_arg args, 'value'
          { name => value }
        end
        unless annotations.blank?
          api.resource(id).annotations.merge!(annotations)
          puts "Set annotations #{annotations.keys} for resource '#{id}'"
        end
      end
    end

    resource.desc "Show an annotation for a resource"
    resource.arg_name "RESOURCE ANNOTATION"
    resource.command :annotation do |c|
      c.action do |global_options, options, args|
        id = full_resource_id require_arg args, 'RESOURCE'
        name = require_arg args, 'ANNOTATION'
        value = api.resource(id).annotations[name]
        puts value unless value.nil?
      end
    end

    resource.desc "Print annotations as JSON"
    resource.arg_name 'RESOURCE'
    resource.command :annotations do |c|
      c.action do |go, o, args|
        id = full_resource_id require_arg args, 'RESOURCE'
        annots = api.resource(id).annotations.to_h
        puts annots.to_json
      end
    end

    resource.desc "List all resources"
    resource.command :list do |c|
      c.desc "Filter by kind"
      c.flag [:k, :kind]

      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options, args
      end
    end
  end
end
