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
require 'conjur/command'

""" 
"""
class Conjur::Command::Init < Conjur::Command
  desc "Obtain values and set up environment variables according to .conjurenv settings, than run external command"
  long_desc "Format of .conjurenv file: 

# Commented lines and empty lines are ignored

# All environment variable names are converted to uppercase
# There are two ways to set up environment variable:

# Environment variable name and Conjur variable ID may be specified explicitly 
ENVIRONMENT_VARIABLE_NAME=CONJUR_VARIABLE_ID

# Line without '=' is considered to be ID of Conjur Environment. 
# All variables from Conjur Environment are converted to environment variables with appropriate (uppercased) names
ENVIRONMENT_NAME  

"

  def self.parse_conjurenv filepath
    conjur_variables={}
    conjur_environments=[]

    File.readlines(filepath).each { |line| 
      line.strip!
      next if line.match(/^#/) or line.empty?
      conjur_environments.push(line) unless row.match(/^(.*)=(.*)$/) { |fields| 
          environment_variable_name, conjur_variable_name = fields[1,2]
          conjur_variables[environment_variable_name]=conjur_variable_name    
      }  
    }

    return { variables: conjur_variables,
             environments: conjur_environments
           } 
  end

  def self.expand_environments environments
    vars = {}
    environments.each { |e| 
      contents = api.environment(e).attributes["variables"]
      contents.each { |k,v| vars[k]=v }
    }
    return vars
  end

  arg_name "-- command [arg1, arg2 ...] "
  Conjur::CLI.command :env do |c|
    c.desc "Environment configuration file"
    c.default_value '.conjurenv'
    c.flag ["f", "file"]

    c.action do |global_options,options,args|

      filename=options[:file] || '.conjurenv'
      exit_now! "File does not exist: #{filename}" unless File.exists? filename
      exit_now! "External command should be provided (with optional args)" if args.empty?

      conjurenv = parse_conjurenv(filename)

      
      conjur_variables = conjurenv[:variables].merge(expand_environments conjurenv[:environments])

      runtime_environment={}

      conjur_variables.each { |environment_name, id| 
        runtime_environment[environment_name.upcase]=api.variable(id).value
      }
      exec runtime_environment, args
    end
  end
end
