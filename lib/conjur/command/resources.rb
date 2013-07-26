require 'conjur/authn'
require 'conjur/resource'
require 'conjur/command'

class Conjur::Command::Resources < Conjur::Command
  self.prefix = :resource

  desc "Create a new resource"
  arg_name "resource-id"
  command :create do |c|
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      resource = api.resource(id)

      if ownerid = options.delete(:ownerid)
        options[:acting_as] = ownerid
      end

      resource.create(options)
      display resource.attributes
    end
  end
  
  desc "Show a resource"
  arg_name "resource-id"
  command :show do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      display api.resource(id).attributes
    end
  end
  
  desc "Determines whether a resource exists"
  arg_name "resource-id"
  command :exists do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      puts api.resource(id).exists?
    end
  end

  desc "Grant a privilege on a resource"
  arg_name "resource-id role privilege"
  command :permit do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      role = require_arg(args, "role")
      privilege = require_arg(args, "privilege")
      api.resource(id).permit privilege, role
      puts "Permission granted"
    end
  end

  desc "Revoke a privilege on a resource"
  arg_name "resource-id role privilege"
  command :deny do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      role = require_arg(args, "role")
      privilege = require_arg(args, "privilege")
      api.resource(id).deny privilege, role
      puts "Permission revoked"
    end
  end

  desc "Check for a privilege on a resource"
  long_desc """
  By default, the privilege is checked for the logged-in user.
  Permission checks may be performed for other roles using the optional role argument.
  When the role argument is used, either the logged-in user must either own the specified
  resource or be an admin of the specified role (i.e. be granted the specified role with grant option).
  """
  arg_name "resource-id privilege"
  command :check do |c|
    c.desc "Role to check. By default, the current logged-in role is used"
    c.flag [:r,:role]

    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      _, kind, resource_id = parse_full_resource_id(id)
      privilege = args.shift or raise "Missing parameter: privilege"
      if role = options[:role]
        role = api.role(role)
        # TODO: change "role:permitted" to get rid of kind
        puts role.permitted? kind, resource_id, privilege
      else
        puts api.resource(id).permitted? privilege
      end
    end
  end

  desc "Grant ownership on a resource to a new owner"
  arg_name "resource-id owner"
  command :give do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      owner = require_arg(args, "owner")
      api.resource(id).give_to owner
      puts "Ownership granted"
    end
  end

  desc "List roles with a specified permission on the resource"
  arg_name "resource-id permission"
  command :permitted_roles do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      permission = require_arg(args, "permission")
      display api.resource(id).permitted_roles(permission)
    end
  end
end
