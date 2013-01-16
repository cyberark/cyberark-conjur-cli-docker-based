require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Roles < Conjur::Command
  self.prefix = :role
  
  desc "Create a new role"
  arg_name "role-id"
  command :create do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role-id"
      role = Conjur::Authn.connect.role(id)
      role.create
    end
  end
  
  desc "Determines whether a role exists"
  arg_name "role-id"
  command :exists do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role-id"
      role = Conjur::Authn.connect.role(id)
      puts role.exists?
    end
  end

  desc "Grant a role to another role"
  arg_name "role-id"
  arg_name "member-id"
  command :grant do |c|
    c.desc "Whether to grant with admin option"
    c.switch :admin
    
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: role-id"
      member = args.shift or raise "Missing parameter: member-id"
      role = Conjur::Authn.connect.role(id)
      role.grant member, options[:admin]
    end
  end
end
