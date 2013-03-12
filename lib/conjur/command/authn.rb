require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Authn < Conjur::Command
  self.prefix = :authn
  
  desc "Logs in and caches credentials to netrc"
  long_desc <<-DESC
After successful login, subsequent commands automatically use the cached credentials. To switch users, login again using the new user credentials.
To erase credentials, use the authn:logout command.

If specified, the CAS server URL should be in the form https://<hostname>/v1.
It should be running the CAS RESTful services at the /v1 path
(or other path as specified by this argument).
DESC
  command :login do |c|
    c.arg_name 'username'
    c.flag [:u,:username]

    c.arg_name 'password'
    c.flag [:p,:password]

    c.arg_name 'CAS server'
    c.desc 'Specifies a CAS server URL to use for login'
    c.flag [:"cas-server"]
    
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
