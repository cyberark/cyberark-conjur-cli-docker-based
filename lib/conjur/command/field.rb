require 'conjur/command'

class Conjur::Command::Field < Conjur::Command
  self.prefix = :field
  
  desc "Selects a field from structured input"
  arg_name "pattern (value | STDIN)"
  command :select do |c|
    c.action do |global_options,options,args|
      pattern = require_arg(args, 'pattern')
      value = args.shift || STDIN.read
      
      require 'json'
      json = JSON.parse(value)
      class << json
        def get_binding
          record = self
          
          binding
        end
      end
      puts json.get_binding.eval(pattern)
    end
  end
end