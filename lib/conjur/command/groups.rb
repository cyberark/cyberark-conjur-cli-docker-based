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
      puts "Created #{group}"
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
      api.role(group.roleid).grant_to member, opts
      puts message
    end
  end

  desc "Remove a group member"
  arg_name "group member"
  command :"members:remove" do |c|
    c.action do |global_options,options,args|
      group = require_arg(args, 'group')
      member = require_arg(args, 'member')
      
      group = api.group(group)
      api.role(group.roleid).revoke_from member
      
      puts "Membership revoked"
    end
  end
end
