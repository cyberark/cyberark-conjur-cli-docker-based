require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Hosts < Conjur::Command
  self.prefix = :host
  
  desc "Enroll a new host into conjur"
  command :enroll do |c|
    c.action do |global_options, options, args|
      host = api.create_host {}
      puts "Created host #{host.id}."
      enrollment_script_url = host.generate_enrollment_script
      puts "On the target host, please execute the following command:"
      puts "sudo true && curl -L #{enrollment_script_url} | sudo bash"
    end
  end
end
