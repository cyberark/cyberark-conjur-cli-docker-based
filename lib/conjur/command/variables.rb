#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Variables < Conjur::Command
  self.prefix = :variable
  
  desc "Create and store a variable"
  arg_name "id?"
  command :create do |c|
    c.arg_name "mime_type"
    c.flag [:m, :"mime-type"], default_value: "text/plain"
    
    c.arg_name "kind"
    c.flag [:k, :"kind"], default_value: "secret"
    
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      id = args.shift
      options[:id] = id if id
      
      mime_type = options.delete(:m)
      kind = options.delete(:k)
      
      options.delete(:"mime-type")
      options.delete(:"kind")
    
      var = api.create_variable(mime_type, kind, options)
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
