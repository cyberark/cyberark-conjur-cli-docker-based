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
    c.desc "Grant with admin option"
    c.switch [:a, :admin]
    
    c.action do |global_options,options,args|
      group = require_arg(args, 'group')
      member = require_arg(args, 'member')
      
      group = api.group(group)
      api.role(group.roleid).grant_to member, !!options[:admin]
    end
  end
end
