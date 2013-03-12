require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Assets < Conjur::Command
  self.prefix = :asset
  
  desc "Show an asset"
  arg_name "kind id"
  command :show do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      id = require_arg(args, "resource-id")
      display api.send(kind, id).attributes
    end
  end

  desc "List an asset"
  arg_name "kind"
  command :list do |c|
    c.action do |global_options,options,args|
      kind = require_arg(args, "kind")
      api.send(kind.pluralize).each do |e|
        display(e, options)
      end
    end
  end
end