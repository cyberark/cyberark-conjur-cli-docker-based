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
#require 'conjur/authn'
#require 'conjur/command'
require 'conjur/conjurenv'
require 'tempfile'

class Conjur::Command::Env < Conjur::Command
  
  desc "Use values of Conjur variables in local context"
  #self.prefix = :env

  def self.common_parameters c
    c.desc "Environment configuration file"
    c.default_value ".conjurenv"
    c.flag ["c"]
    
    c.desc "Environment configuration as inline yaml"
    c.flag ["yaml"]
  end

  def self.get_env_object options
    if options[:yaml] and options[:c]!='.conjurenv'
      exit_now! "Options -c and --yaml can not be provided together"
    end

    env = if options[:yaml] 
            Conjur::Env.new(yaml: options[:yaml])
          else
            Conjur::Env.new(file: (options[:c]||'.conjurenv'))
          end
    return env
  end

  command :env do |env|
    env.desc "Execute external command with environment variables populated from Conjur"
    env.long_desc <<'RUNLONGDESC' 
Processes environment configuration (see env:help for details), and executes a command (with optional arguments) in the modified environment.
Local names are uppercased and used as names of environment variables. 

Consider following environment configuration: 

{ key_pair_name: jenkins_key, ssh_keypair_path: !tmp jenkins/private_key, api_key: !var jenkins/api_key }

Values of the variables "jenkins/private_key" and "jenkins/api_key" will be obtained from Conjur. Value of "jenkins/api_key" will be associated with local name 'api_key'. Value of "jenkins/private_key" will be stored in the temporary file, which name will be associated with local name "ssh_keypair_path". 

Than, external command with appropriate arguments will be launched in the environment which has following variables:

KEY_PAIR_NAME="jenkins_key",
SSH_KEYPAIR_PATH="/dev/shm/temp_file_with_key_obtained_from_Conjur",
API_KEY="api key obtained from Conjur"
RUNLONGDESC
    env.arg_name "-- command [arg1, arg2 ...] "
    env.command :run do |c|
      common_parameters(c)

      c.action do |global_options,options,args|
        if args.empty? 
          exit_now! "External command with optional arguments should be provided"
        end
        env = get_env_object(options)
        runtime_environment = Hash[ env.obtain(api).map {|k,v| [k.upcase, v] } ]
        if Conjur.log 
          Conjur.log << "[conjur env] Loaded environment #{runtime_environment.keys}\n"
          Conjur.log << "[conjur env] Running command #{args}\n"
        end
        Kernel.system(runtime_environment, *args) or exit($?.to_i) # keep original exit code in case of failure
      end
    end

    env.desc "Check availability of Conjur variables" 
    env.long_desc "Checks availability of Conjur variables mentioned in an environment configuration (see env:help for details), and prints out each local name and appropriate status"
    env.command :check do |c|
      common_parameters(c)
      c.action do |global_options,options,args|
        env = get_env_object(options)
        result = env.check(api)
        result.each { |k,v| puts "#{k}: #{v}" }
        raise "Some variables are not available" unless result.values.select {|v| v == :unavailable }.empty?
      end
    end # command

    env.desc "Render ERB template with variables obtained from Conjur"
    env.long_desc <<'TEMPLATEDESC' 
Processes environment configuration (see env:help for details), and creates a temporary file, which contains result of ERB template rendering in appropriate context.
Template should refer to Conjur values by local name as "%<= conjurenv['local_name'] %>".

Consider following environment configuration: 

{ key_pair_name: jenkins_key, ssh_keypair_path: !tmp jenkins/private_key, api_key: !var jenkins/api_key }

Values of the variables "jenkins/private_key" and "jenkins/api_key" will be obtained from Conjur. Value of "jenkins/api_key" will be associated with local name 'api_key'. Value of "jenkins/private_key" will be stored in the temporary file, which name will be associated with local name "ssh_keypair_path". 

Than, following template 

key_pair=<%= conjurenv["key_pair_name"] %>, path_to_ssh_key= <%= conjurenv["ssh_keypair_path"] %>, api_key = '<%= conjurenv["api_key"] %>'

will be rendered to 

key_pair=jenkins_key, path_to_ssh_key=/dev/shm/temp_file_with_key_obtained_from_Conjur, api_key='api key obtained from Conjur'

Result of the rendering will be stored in temporary file, which location is than printed to stdout
TEMPLATEDESC
    env.arg_name "template.erb" 

    env.command :template do |c|
      common_parameters(c)

      c.action do |global_options,options,args|
        template_file = args.first
        exit_now! "Location of readable ERB template should be provided" unless template_file and File.readable?(template_file)
        template = File.read(template_file)
        env = get_env_object(options)
        conjurenv = env.obtain(api)  # needed for binding
        rendered = ERB.new(template).result(binding)

        # 
        tempfile = if File.directory?("/dev/shm") and File.writable?("/dev/shm")
                      Tempfile.new("conjur","/dev/shm")
                   else
                      Tempfile.new("conjur")
                   end
        tempfile.write(rendered)
        tempfile.close()
        old_path = tempfile.path
        new_path = old_path+".saved"
        FileUtils.copy(old_path, new_path) # prevent garbage collection
        puts new_path
      end
    end

    env.desc "Print description of environment configuration format" 
    env.command :help do |c|
      c.action do |global_options,options,args|
        puts """
Environment configuration (either stored in file referred by -c option or provided inline with --yaml option) should be a YAML document describing one-level Hash.
Keys of the hash are 'local names', used to refer to variable values in convenient manner.  (See help for env:run and env:template for more details about how they are interpreted).

Values of the hash may take one of the following forms: a) string b) string preceeded with !var tag c) string preceeded with !tmp tag.

a) Plain string is just associated with local name without any calls to Conjur.

b) String preceeded by !var tag is interpreted as an ID of the Conjur variable, which value should be obtained and associated with appropriate local name.

c) String preceeded by !tmp tag is interpreted as an ID of the Conjur variable, which value should be stored in temporary file, which location should in turn be associated with appropriate local name.

Example of environment configuration: 

{ local_variable_1: 'literal value', local_variable_2: !var id/of/Conjur/Variable , local_variable_3: !tmp id/of/another/Conjur/variable }

""" 
      end
    end

  end
end
