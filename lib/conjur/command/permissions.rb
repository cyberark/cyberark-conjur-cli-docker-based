require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Resources < Conjur::Command
  self.prefix = :permission
  
  desc "Grants permission on a resource to a role"
  arg_name "resource-kind"
  arg_name "resource-id"
  arg_name "role"
  arg_name "privilege"
  command :grant do |c|
    c.desc "Whether to give the grant option"
    c.switch :grant
    
    c.action do |global_options,options,args|
      kind = args.shift or raise "Missing parameter: resource-kind"
      resource_id = args.shift or raise "Missing parameter: resource-id"
      role = args.shift or raise "Missing parameter: role"
      privilege = args.shift or raise "Missing parameter: privilege"
      resource = Conjur::Authn.connect.resource(kind, resource_id)
      options = {}
      options[:grant_option] = true if options[:grant]
      resource.permit privilege, role, options
    end
  end
  
  desc "Check whether a role has a privilege on a resource"
  arg_name "resource-kind"
  arg_name "resource-id"
  arg_name "role"
  arg_name "privilege"
  command :check do |c|
    c.action do |global_options,options,args|
      kind = args.shift or raise "Missing parameter: resource-kind"
      resource_id = args.shift or raise "Missing parameter: resource-id"
      role = args.shift or raise "Missing parameter: role"
      privilege = args.shift or raise "Missing parameter: privilege"
      role = Conjur::Authn.connect.role(role)
      begin
        role.permitted? kind, resource_id, privilege
        puts "true"
      rescue RestClient::ResourceNotFound
        puts "false"
      end
    end
  end
end
