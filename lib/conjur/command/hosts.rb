require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Hosts < Conjur::Command
  self.prefix = :host

  desc "Create a new host"
  arg_name "host"
  command :create do |c|
    c.arg_name "password"
    c.flag [:p,:password]
    
    acting_as_option(c)

    c.action do |global_options,options,args|
      id = args.shift
      options[:id] = id if id
      display api.create_host(options), options
    end
  end
  
  desc "Enroll a new host into conjur"
  arg_name "host"
  command :enroll do |c|
    c.action do |global_options, options, args|
      id = require_arg(args, 'host')
      enrollment_url = api.host(id).enrollment_url
      puts enrollment_url
      $stderr.puts "On the target host, please execute the following command:"
      $stderr.puts "curl -L #{enrollment_url} | bash"
    end
  end
end
