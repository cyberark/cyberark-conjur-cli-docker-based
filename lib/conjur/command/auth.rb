require 'conjur/auth'
require 'conjur/command'

class Conjur::Command::Auth < Conjur::Command
  self.prefix = :auth
  
  command :login do |c|
    c.action do
      Conjur::Auth.login
    end
  end
end
