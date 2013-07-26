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
  
  desc "Check whether a role has a privilege on a resource"
  arg_name "resource-id role privilege"
  command :check do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      _, kind, resource_id = parse_full_resource_id(id)

      role = args.shift or raise "Missing parameter: role"
      privilege = args.shift or raise "Missing parameter: privilege"
      role = api.role(role)
      #TODO: change "role:permitted" to get rid of kind
      puts role.permitted? kind, resource_id, privilege
    end
  end

  desc "Grant ownership on a resource to a new owner"
  arg_name "resource-id owner"
  command :give do |c|
    c.action do |global_options,options,args|
      id = full_resource_id( require_arg(args, "resource-id") )
      owner = require_arg(args, "owner")
      api.resource(id).give_to owner
      puts "Role granted"
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
