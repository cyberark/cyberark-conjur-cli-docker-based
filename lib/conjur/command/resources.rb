require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Resources < Conjur::Command
  self.prefix = :resource
  
  desc "Create a new resource"
  arg_name "kind"
  arg_name "resource-id"
  command :create do |c|
    c.action do |global_options,options,args|
      kind = args.shift or raise "Missing parameter: kind"
      id = args.shift or raise "Missing parameter: resource-id"
      resource = api.resource(kind, id)
      resource.create
    end
  end
  
  desc "Determines whether a resource exists"
  arg_name "kind"
  arg_name "resource-id"
  command :exists do |c|
    c.action do |global_options,options,args|
      kind = args.shift or raise "Missing parameter: kind"
      id = args.shift or raise "Missing parameter: resource-id"
      resource = api.resource(kind, id)
      puts resource.exists?
    end
  end
end
