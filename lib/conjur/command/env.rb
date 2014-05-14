#
# Copyright (C) 2014 Conjur Inc
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
require 'tempfile'

class Conjur::Command::Env < Conjur::Command


  class CustomTag
    def initialize id 
      @id=id
    end
    def init_with(coder)
      initialize(coder.scalar)
    end
    def conjur_id
      @id
    end
  end

  class ConjurVariable < CustomTag
    def evaluate value
      value.chomp
    end
  end
  class ConjurTempfile < CustomTag
    def evaluate value
      @tempfile = Tempfile.new("conjur","/dev/shm")
      @tempfile.write(value)
      @tempfile.chmod(0600)
      @tempfile.close
      @tempfile.path
    end
  end


  def self.parse_conjurenv filepath
    YAML.add_tag("!var", ConjurVariable)
    YAML.add_tag("!tmp", ConjurTempfile)

    contents = YAML.load(File.read(filepath)) # File.read to make testing easier
    values_ok = contents.values.all? {|v| v.kind_of?(String) or v.kind_of?(CustomTag) } rescue false
    unless values_ok
      exit_now! "File #{filepath} should contain one-level Hash with scalar values"
    end
    return contents
  end

  def self.obtain_values definition
    runtime_environment={}
    $stderr.puts "DEBUG: #{definition}"
    variable_ids= definition.values.map { |v| v.conjur_id rescue nil }.compact

    conjur_values=api.variable_values(variable_ids)

    definition.each{ |environment_name, reference| 
      runtime_environment[environment_name.upcase]= if reference.respond_to?(:evaluate)
                                                      reference.evaluate( conjur_values[reference.conjur_id] )
                                                    else
                                                      reference # is a literal value
                                                    end
    }
    return runtime_environment
  end

  def self.check_variables definition
    all_ok=true
    definition.values.map { |v| v.conjur_id rescue nil }.compact.each { |v|
      variable_ok = api.resource("variable:"+v).permitted? :execute
      puts "#{v}: #{if variable_ok then "" else "not " end }available"
      all_ok=false unless variable_ok
    }
    exit_now! "Some variables are not available" unless all_ok
  end

  desc "Obtain values and set up environment variables according to .conjurenv settings, than run external command"
  arg_name "-- command [arg1, arg2 ...] "
  Conjur::CLI.command :env do |c|
    c.desc "Environment configuration file"
    c.default_value '.conjurenv'
    c.flag ["f", "file"]

    c.desc "Perform check of variables availability and exit"  
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
        $stderr.puts "Runtime environment: #{runtime_environment}, args: #{args}"
        Kernel.exec(runtime_environment, *args)
      else
        check_variables( parse_conjurenv(filename) )
      end
    end
  end
end
