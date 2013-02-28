require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Roles < Conjur::Command
  self.prefix = :role
  
  desc "Create a new role"
  arg_name "role"
  command :create do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role"
      role = api.role(id)
      role.create
    end
  end
  
  desc "Determines whether a role exists"
  arg_name "role"
  command :exists do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role"
      role = api.role(id)
      puts role.exists?
    end
  end

  desc "Lists role memberships"
  arg_name "role"
  command :memberships do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      display api.role(id).all.map(&:id)
    end
  end

  desc "Grant a role to another role. You must have admin permission on the granting role."
  arg_name "role"
  arg_name "member-id"
  command :grant_to do |c|
    c.desc "Whether to grant with admin option"
    c.switch :admin
    
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role"
      member = args.shift or raise "Missing parameter: member-id"
      role = api.role(id)
      role.grant_to member, options[:admin]
    end
  end

  desc "Revoke a role from another role."
  arg_name "role"
  arg_name "member-id"
  command :revoke_from do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role"
      member = args.shift or raise "Missing parameter: member-id"
      role = api.role(id)
      role.revoke_from member
    end
  end
end
