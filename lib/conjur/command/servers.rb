require 'conjur/auth'
require 'conjur/command'

class Conjur::Command::Auth < Conjur::Command
  self.prefix = :server
  
  desc "Enroll a new server into conjur"
  command :enroll do |c|
    c.action do |global_options, options, args|
      api = Conjur::Auth.api
      name = args.shift || random_name
      server = api.create_server id: name
      puts "Created server #{name}."
      enrollment_script_url = server.generate_enrollment_script
      puts "On the target server, please execute the following command:"
      puts "$ sudo true && curl -L #{enrollment_script_url} | sudo bash"
    end
  end
  
  def self.random_name
    require 'rufus/mnemo'
    Rufus::Mnemo.to_s(rand(1e5))
  end
end
