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
  
  def self.parse_conjurenv filepath
    contents = YAML.load(File.read(filepath)) # File.read to make testing easier
    values_ok = contents.values.all? {|v| v.kind_of?(String) } rescue false
    unless values_ok
      exit_now! "File #{filepath} should contain one-level Hash with strings as values"
    end
    return contents
  end

  def self.obtain_values conjur_variables
    runtime_environment={}
    variable_ids=conjur_variables.values
    begin  
      # returns hash of id=>value
      conjur_values=api.variable_values(variable_ids)
      conjur_variables.each{ |environment_name, id| 
        runtime_environment[environment_name.upcase]=conjur_values[id]
      }
    rescue # whatever
      $stderr.puts "Warning: batch retrieval failed, processing variables one by one"
      conjur_variables.each { |environment_name, id| 
        runtime_environment[environment_name.upcase]=api.variable(id).value
      }
    end
    return runtime_environment
  end

  def self.check_variables conjur_variables
    all_ok=true
    conjur_variables.values.each { |v|  
      variable_ok = api.resource("variable:"+v).permitted? :execute
      puts "#{v}: #{if variable_ok then "" else "not " end }available"
      all_ok=false unless variable_ok
    }
    exit_now! "Some variables are not available" unless all_ok
  end

  desc "Create and store a variable"
  arg_name "id"
  command :create do |c|
    c.arg_name "mime_type"
    c.flag [:m, :"mime-type"], default_value: "text/plain"
    
    c.arg_name "kind"
    c.flag [:k, :"kind"], default_value: "secret"
    
    c.arg_name "value"
    c.desc "Initial value"
    c.flag [:v, :"value"]
    
    acting_as_option(c)
    
    c.action do |global_options,options,args|
      id = args.shift
      options[:id] = id if id
      
      unless id
        ActiveSupport::Deprecation.warn "id argument will be required in future releases"
      end
      
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

  desc "List variables"
  command :list do |c|
    command_options_for_list c

    c.action do |global_options, options, args|
      command_impl_for_list global_options, options.merge(kind: "variable"), args
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
  
  desc "Obtain values and set up environment variables according to .conjurenv settings, than run external command"
  arg_name "-- command [arg1, arg2 ...] "
  command :values do |c|
    c.desc "Environment configuration file"
    c.default_value '.conjurenv'
    c.flag ["f", "file"]

    c.desc "Perform check of variables availability"  
    c.switch ["check"]

    c.action do |global_options,options,args|

      if options[:check] and not args.empty? 
        exit_now! "Options '--check' and '#{args}' can not be provided together"
      elsif args.empty? and not options[:check]
        exit_now! "Either --check or '-- external_command' option should be provided"
      end

      filename=options[:file] || '.conjurenv'
      exit_now! "File does not exist: #{filename}" unless File.exists? filename

      unless options[:check] 
        runtime_environment = obtain_values( parse_conjurenv(filename) )
        Kernel.exec(runtime_environment, args)
      else
        check_variables( parse_conjurenv(filename) )
      end
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

  desc "Store value into temporary file and print out it's name" 
  arg_name "variable"
  command :"to_file" do |c|
    c.desc "Version number"
    c.flag [:v, :version]
    c.action do |global_options,options,args|
      id = require_arg(args, 'variable')
      value = api.variable(id).value(options[:version])
      tempfile = `mktemp /dev/shm/conjur.XXXXXX`.strip
      File.open(tempfile,'w') { |f| f.write(value) }
      puts tempfile
    end
    
  end
end
