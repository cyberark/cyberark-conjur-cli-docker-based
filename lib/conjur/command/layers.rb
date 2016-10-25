require 'conjur/command'

class Conjur::Command::Layers < Conjur::Command

  # Form an account:kind:hostid from the host argument
  # Or interpret a fully-qualified role id
  def self.require_hostid_arg(args)
    hostid = require_arg(args, 'HOST')
    unless hostid.index(':')
      hostid = [ Conjur::Core::API.conjur_account, 'host', hostid ].join(':')
    end
    hostid
  end

  def self.interpret_layer_privilege(privilege)
    case privilege
      when 'execute'
        'use_host'
      when 'update'
        'admin_host'
      else
        exit_now! "Invalid privilege '#{privilege}'. Acceptable values are : execute, update"
    end
  end

  def self.parse_layer_permission_args(global_options, options, args)
    id = require_arg(args, "LAYER")
    role = require_arg(args, "ROLE")
    privilege = require_arg(args, "PRIVILEGE")
    role_name = interpret_layer_privilege privilege
    [ id, role_name, role ]
  end

  desc "Operations on layers"
  command :layer do |layer|
    layer.desc "List layers"
    layer.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "layer"), args
      end
    end

    layer.desc "Show a layer"
    layer.arg_name "LAYER"
    layer.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'LAYER')
        display(api.layer(id), options)
      end
    end

    layer.desc "Operations on hosts"
    layer.command :hosts do |hosts|
      hosts.desc "List roles that have permission on the hosts"
      hosts.arg_name "LAYER PRIVILEGE"
      hosts.command :permitted_roles do |c|
        c.action do |global_options,options,args|
          id = require_arg(args, 'LAYER')
          role_name = interpret_layer_privilege require_arg(args, 'PRIVILEGE')

          members = api.layer(id).hosts_members(role_name).map(&:member).select do |m|
            m.kind != "@"
          end
          display members.map(&:roleid)
        end
      end
    end
  end
end
