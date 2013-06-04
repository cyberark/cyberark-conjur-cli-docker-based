require 'conjur/command'

class Conjur::Command::Id < Conjur::Command
  self.prefix = :id

  desc "Creates a new unique id"
  command :create do |c|
    c.action do |global_options,options,args|
      var = api.create_variable("text/plain", "unique-id", {})
      puts var.id
    end
  end
end