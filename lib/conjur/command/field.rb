require 'conjur/command'

class Conjur::Command::Field < Conjur::Command
  self.prefix = :field
  
  desc "(Deprecated. See standalone jsonfield command instead.)"
  command :select do |c|
    c.action do |global_options,options,args|
      pattern = require_arg(args, 'pattern')
      value = args.shift || STDIN.read

      warn "field:select is deprecated. Please use jsonfield command instead."
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