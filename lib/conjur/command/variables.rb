require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Variables < Conjur::Command
  self.prefix = :variable
  
  desc "Create and store a variable"
  command :create do |c|
    c.arg_name "mime_type"
    c.flag [:m, :"mime-type"]
    
    c.arg_name "kind"
    c.flag [:k, :"kind"]
    
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      var = api.create_variable(options[:m], options[:k], options)
      display(var, options)
    end
  end

  desc "Show a variable"
  arg_name "id"
  command :show do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'id')
      display(api.variable(id), options)
    end
  end

  desc "Add a value"
  arg_name "variable ( value | STDIN )"
  command :"values:add" do |c|
    c.action do |global_options,options,args|
      id = require_arg(args, 'variable')
      value = args.shift || STDIN.read
      
      api.variable(id).add_value(value)
      puts "Value added"
    end
  end

  desc "Get a value"
  arg_name "variable"
  command :value do |c|
    c.desc "Version number"
    c.flag [:v, :version]
    
    c.action do |global_options,options,args|
      id = require_arg(args, 'variable')
      $stdout.write api.variable(id).value(options[:version])
    end
  end
end
