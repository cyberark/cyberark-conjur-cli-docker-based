require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Resources < Conjur::Command
  self.prefix = :resource
  
  desc "Create a new resource"
  arg_name "kind resource-id"
  command :create do |c|
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      resource = api.resource(kind, id)
      resource.create(options)
    end
  end
  
  desc "Show a resource"
  arg_name "kind resource-id"
  command :show do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      display api.resource(kind, id).attributes
    end
  end
  
  desc "Determines whether a resource exists"
  arg_name "kind resource-id"
  command :exists do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      resource = api.resource(kind, id)
      puts resource.exists?
    end
  end

  desc "Grant a privilege on a resource"
  arg_name "kind resource-id role privilege"
  command :permit do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      role = require_arg(args, "role")
      privilege = require_arg(args, "privilege")
      api.resource(kind, id).permit privilege, role
    end
  end

  desc "Revoke a privilege on a resource"
  arg_name "kind resource-id role privilege"
  command :deny do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      role = require_arg(args, "role")
      privilege = require_arg(args, "privilege")
      api.resource(kind, id).deny privilege, role
    end
  end

  desc "Grant ownership on a resource to a new owner"
  arg_name "kind resource-id owner"
  command :give do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      owner = require_arg(args, "owner")
      api.resource(kind, id).give_to owner
    end
  end

  desc "List roles with a specified permission on the resource"
  arg_name "kind resource-id permission"
  command :permitted_roles do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      permission = require_arg(args, "permission")
      display api.resource(kind, id).permitted_roles(permission)
    end
  end
end
