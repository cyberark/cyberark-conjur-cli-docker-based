require 'conjur/command'

class Conjur::Command::Layers < Conjur::Command


  # Form an account:kind:hostid from the host argument
  # Or interpret a fully-qualified role id
  def self.require_hostid_arg(args)
    hostid = require_arg(args, 'host')
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
    id = require_arg(args, "layer")
    role = require_arg(args, "role")
    privilege = require_arg(args, "privilege")
    role_name = interpret_layer_privilege privilege
    [ id, role_name, role ]
  end

  desc "Operations on layers"
  command :layer do |layer|

    layer.desc "Create a new layer"
    layer.arg_name "id"
    layer.command :create do |c|
      acting_as_option(c)

      c.action do |global_options,options,args|
        id = require_arg(args, 'id')

        layer = api.create_layer(id, options)
        display(layer, options)
      end
    end

    layer.desc "List layers"
    layer.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "layer"), args
      end
    end

    layer.desc "Show a layer"
    layer.arg_name "id"
    layer.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'id')
        display(api.layer(id), options)
      end
    end

    layer.desc "Lists all direct members of the layer. The membership list is not recursively expanded."
    layer.arg_name "layer"
    layer.command :members do |c|
      c.action do |global_options,options,args|
        layer = require_arg(args, 'layer')

        display_members api.layer(layer).members, options
      end
    end

    layer.desc "Provision a layer by creating backing resources in an IaaS / PaaS system"
    layer.arg_name "layer"
    layer.command :provision do |c|
      c.desc "Provisioner to use (aws)"
      c.arg_name "provisioner"
      c.flag [ :provisioner ]

      c.desc "Variable holding a credential used to connect to the provisioner"
      c.arg_name "variableid"
      c.flag [ :credential ]

      c.desc "AWS bucket to contain the bootstrap credentials (will be created if missing)"
      c.arg_name "bucket"
      c.flag [ :bucket ]

      c.action do |global_options, options, args|
        id = require_arg(args, 'layer')
        provisioner = options[:provisioner] or exit_now!("Missing argument: provisioner")
        credential = options[:credential] or exit_now!("Missing argument: credential")
        bucket = options[:bucket] or exit_now!("Missing argument: bucket")
        raise "Supported provisioners: aws" unless provisioner == "aws"

        require "conjur/provisioner/layer/aws"

        layer = api.layer(id)
        class << layer
          include Conjur::Provisioner::Layer::AWS
        end
        layer.aws_bucket_name = bucket
        layer.aws_credentialid = credential
        layer.provision

        puts "Layer provisioned by #{provisioner}"
      end
    end

    layer.desc "Operations on hosts"
    layer.command :hosts do |hosts|
      hosts.desc "Permit a privilege on hosts in the layer"
      hosts.long_desc <<-DESC
Privilege may be : execute, update
      DESC
      hosts.arg_name "layer role privilege"
      hosts.command :permit do |c|
        c.action do |global_options,options,args|
          id, role_name, role = parse_layer_permission_args(global_options, options, args)
          api.layer(id).add_member role_name, role
          puts "Permission granted"
        end
      end

      hosts.desc "Remove a privilege on hosts in the layer"
      hosts.arg_name "layer role privilege"
      hosts.command :deny do |c|
        c.action do |global_options,options,args|
          id, role_name, role = parse_layer_permission_args(global_options, options, args)
          api.layer(id).remove_member role_name, role
          puts "Permission removed"
        end
      end

      hosts.desc "List roles that have permission on the hosts"
      hosts.arg_name "layer privilege"
      hosts.command :permitted_roles do |c|
        c.action do |global_options,options,args|
          id = require_arg(args, "layer")
          role_name = interpret_layer_privilege require_arg(args, "privilege")

          members = api.layer(id).hosts_members(role_name).map(&:member).select do |m|
            m.kind != "@"
          end
          display members.map(&:roleid)
        end
      end

      hosts.desc "Add a host to an layer"
      hosts.arg_name "layer host"
      hosts.command :add do |c|
        c.action do |global_options, options, args|
          id = require_arg(args, 'layer')
          hostid = require_hostid_arg(args)

          api.layer(id).add_host hostid
          puts "Host added"
        end
      end

      hosts.desc "Remove a host from an layer"
      hosts.arg_name "layer host"
      hosts.command :remove do |c|
        c.action do |global_options, options, args|
          id = require_arg(args, 'layer')
          hostid = require_hostid_arg(args)

          api.layer(id).remove_host hostid
          puts "Host removed"
        end
      end
    end
  end
end
