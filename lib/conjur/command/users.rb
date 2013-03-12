require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Users < Conjur::Command
  self.prefix = :user
  
  desc "Create a new user"
  arg_name "login"
  command :create do |c|
    c.desc "Prompt for a password for the user"
    c.switch [:p,:password]
    
    c.action do |global_options,options,args|
      login = require_arg(args, 'login')
      
      opts = {}
      if options[:p]
        hl = HighLine.new
        password = hl.ask("Enter the password (it will not be echoed): "){ |q| q.echo = false }
        confirmation = hl.ask("Confirm the password: "){ |q| q.echo = false }
        
        raise "Password does not match confirmation" unless password == confirmation
        
        opts[:password] = password
      end
      
      display api.create_user(login, opts)
    end
  end
end
