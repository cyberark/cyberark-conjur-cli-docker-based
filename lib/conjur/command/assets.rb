require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Assets < Conjur::Command
  self.prefix = :asset

  desc "Create an asset"
  arg_name "kind id"
  command :create do |c|
    acting_as_option(c)
    
    c.action do |global_options, options, args|
      kind = require_arg(args, 'kind').gsub('-', '_')
      
      m = "create_#{kind}"
      record = if [ 1, -1 ].member?(api.method(m).arity)
        id = args.shift
        if id
          options[:id] = id
        end
        api.send(m, options)
      else
        id = require_arg(args, 'id')
        api.send(m, id, options)
      end
      display(record, options)
    end
  end
  
  desc "Show an asset"
  arg_name "kind id"
  command :show do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind").gsub('-', '_')
      id = require_arg(args, "resource-id")
      display api.send(kind, id).attributes
    end
  end

  desc "Checks for the existance of an asset"
  arg_name "kind id"
  command :exists do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind").gsub('-', '_')
      id = require_arg(args, "id")
      puts api.send(kind, id).exists?
    end
  end

  desc "List an asset"
  arg_name "kind"
  command :list do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind").gsub('-', '_')
      api.send(kind.pluralize).each do |e|
        display(e, options)
      end
    end
  end

  desc "Add a member to an asset"
  arg_name "kind id role-name member"
  command :"members:add" do |c|
    c.desc "Grant with admin option"
    c.flag [:a, :admin]

    c.action do |global_options, options, args|
      kind = require_arg(args, "kind").gsub('-', '_')
      id = require_arg(args, "resource-id")
      role_name = require_arg(args, 'role-name')
      member = require_arg(args, 'member')
      admin_option = !options.delete(:admin).nil?
      
      asset = api.send(kind, id)
      tokens = [ asset.resource_kind, asset.resource_id, role_name ]
      grant_role = [ asset.core_conjur_account, '@', tokens.join('/') ].join(':')
      api.role(grant_role).grant_to member, admin_option
      
      puts "Membership granted"
    end
  end

  desc "Remove a member from an asset"
  arg_name "kind id role-name member"
  command :"members:remove" do |c|
    c.action do |global_options, options, args|
      kind = require_arg(args, "kind").gsub('-', '_')
      id = require_arg(args, "resource-id")
      role_name = require_arg(args, 'role-name')
      member = require_arg(args, 'member')
      admin_option = !options.delete(:admin).nil?
      
      asset = api.send(kind, id)
      tokens = [ asset.resource_kind, asset.resource_id, role_name ]
      grant_role = [ asset.core_conjur_account, '@', tokens.join('/') ].join(':')
      api.role(grant_role).revoke_from member
      
      puts "Membership revoked"
    end
  end
end