require 'conjur/api/authn'
require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Users < Conjur::Command
  self.prefix = :user
  
  def self.prompt_for_password
    # use stderr to allow output redirection, e.g.
    # conjur user:create -p username > user.json
    hl = HighLine.new($stdin, $stderr)

    password = hl.ask("Enter the password (it will not be echoed): "){ |q| q.echo = false }
    confirmation = hl.ask("Confirm the password: "){ |q| q.echo = false }
    
    raise "Password does not match confirmation" unless password == confirmation
    
    password
  end
  
  desc "Create a new user"
  arg_name "login"
  command :create do |c|
    c.desc "Prompt for a password for the user (default: --no-password)"
    c.switch [:p,:password]
    
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      login = require_arg(args, 'login')
      
      opts = options.slice(:ownerid)

      if options[:p]
        opts[:password] = prompt_for_password
      end
      
      display api.create_user(login, opts)
    end
  end

  desc "Update the password of the logged-in user"
  command :update_password do |c|
    c.desc "Password to use, otherwise you will be prompted"
    c.flag [:p,:password]

    c.action do |global_options,options,args|
      username, password = Conjur::Authn.read_credentials
      new_password = options[:password] || prompt_for_password
      
      Conjur::API.update_password username, password, new_password
    end
  end
end
