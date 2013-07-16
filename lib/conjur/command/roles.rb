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
    c.switch :admin
    
    c.action do |global_options,options,args|
      id = require_arg(args, 'role')
      member = require_arg(args, 'member')
      role = api.role(id)
      role.grant_to member, options[:admin]
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
