require 'conjur/auth'
require 'conjur/command'

class Conjur::Command::Auth < Conjur::Command
  self.prefix = :auth
  
  command :login do |c|
    c.arg_name 'username'
    c.flag [:u,:username]

    c.arg_name 'password'
    c.flag [:p,:password]
    
    c.action do |global_options,options,args|
      Conjur::Auth.login(options)
    end
  end
end
