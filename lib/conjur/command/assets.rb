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
      record = if api.method(m).arity == 1
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
end