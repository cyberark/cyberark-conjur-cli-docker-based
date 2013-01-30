require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Values < Conjur::Command
  self.prefix = :secret
  
  desc "Create and store a secret"
  arg_name "secret"
  command :create do |c|
    c.action do |global_options,options,args|
      secret = args.shift or raise "Missing parameter: secret"
      value = Conjur::Authn.connect.create_secret(secret)
      puts "Created #{value.identifier}"
    end
  end

  desc "Retrieve a secret"
  arg_name "id"
  command :value do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: id"
      value = Conjur::Authn.connect.secret(id).value
      puts value
    end
  end
end
