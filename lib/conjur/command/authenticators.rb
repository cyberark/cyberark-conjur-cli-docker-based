class Conjur::Command::Authenticators < Conjur::Command

  desc "Manage authenticators"
  command :authenticator do |authenticator|
    authenticator.desc "Enable an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :enable do |c|
      c.action do |global_options,options,args|
        authn_id = require_arg(args, "AUTHENTICATOR")
        id = full_resource_id("webservice:conjur/#{authn_id}")

        puts "Enabling #{id}..."
        # display api.resource(id).attributes
      end
    end

    authenticator.desc "Disable an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :disable do |c|
      c.action do |global_options,options,args|
        authn_id = require_arg(args, "AUTHENTICATOR")
        id = full_resource_id("webservice:conjur/#{authn_id}")
        
        puts "Disabling #{id}..."
        # display api.resource(id).attributes
      end
    end

    authenticator.desc "Check the status of an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :status do |c|
      c.action do |global_options,options,args|
        authn_id = require_arg(args, "AUTHENTICATOR")
        id = full_resource_id("webservice:conjur/#{authn_id}")

        puts "Getting status #{id}..."
        # display api.resource(id).attributes
      end
    end
  end
end
