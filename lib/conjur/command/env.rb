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
  def self.parse_conjurenv filepath
    contents = YAML.load(File.read(filepath)) # File.read to make testing easier
    values_ok = contents.values.all? {|v| v.kind_of?(String) } rescue false
    unless values_ok
      exit_now! "File #{filepath} should contain one-level Hash with strings as values"
    end
    return contents
  end

  def self.to_tempfile value
    container = Tempfile.open("/dev/shm/conjur")
    container.write(value)
    container.chmod(0600)
    container.close
    container.path
  end

  def self.obtain_values conjur_variables
    runtime_environment={}
    variable_ids=conjur_variables.values.map {|v| v.gsub(/^@/,'') } # cut off prefices
    conjur_values=api.variable_values(variable_ids)
    conjur_variables.each{ |environment_name, id| 
      runtime_environment[environment_name.upcase]= if id.starts_with?("@") 
                                                      plain_id=id.gsub(/^@/,'')
                                                      to_tempfile( conjur_values[plain_id] )
                                                    else
                                                      conjur_values[id]
                                                    end
    }
    return runtime_environment
  end
  def self.check_variables conjur_variables
    all_ok=true
    conjur_variables.values.each { |v|  
      v.gsub!(/^@/,"") 
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
        Kernel.exec(runtime_environment, args)
      else
        check_variables( parse_conjurenv(filename) )
      end
    end
  end
end
