require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Secrets < Conjur::Command
  self.prefix = :secret
  
  desc "Create and store a secret"
  arg_name "secret"
  command :create do |c|
    acting_as_option(c)

    c.action do |global_options,options,args|
      secret = args.shift or raise "Missing parameter: secret"
      display api.create_secret(secret, options), options
    end
  end

  desc "Retrieve a secret"
  arg_name "id"
  command :value do |c|
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: id"
      puts api.secret(id).value
    end
  end
end
