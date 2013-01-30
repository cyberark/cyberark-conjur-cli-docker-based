require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Authn < Conjur::Command
  self.prefix = :authn
  
  desc "Logs in and caches credentials to netrc"
  command :login do |c|
    c.arg_name 'username'
    c.flag [:u,:username]

    c.arg_name 'password'
    c.flag [:p,:password]
    
    c.action do |global_options,options,args|
      Conjur::Authn.login(options)
    end
  end
  
  desc "Logs out"
  command :logout do |c|
    c.action do
      Conjur::Authn.delete_credentials
    end
  end
end
