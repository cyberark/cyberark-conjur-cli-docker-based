#
# Copyright (C) 2014-2016 Conjur Inc
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

class Conjur::Command::Bootstrap < Conjur::Command
  desc "Create initial users, groups, and permissions"
  long_desc %Q(When you launch a new Conjur master server, it contains only one login: the "admin" user. 
  The bootstrap command will finish the setup of a new Conjur system by creating other essential records.

  Actions performed by "bootstrap" include:

  * Creation of a group called "security_admin".

  * Giving the "security_admin" the power to manage public keys.

  * Creation of a user called "attic", which will be the owner of retired records.
  
  * Create some system identities, for use by system services.

  * Storing the "attic" user's API key in a variable called "conjur/users/attic/api-key".

  * (optional) Create a new user who will be made a member and admin of the "security_admin" group.

  * (optional) If a new user was created, login as that user.
  )
  
  class BootstrapListener
    def echo msg
      $stderr.puts msg
    end
  end

  Conjur::CLI.command :bootstrap do |c|
    c.desc "Don't perform up-front checks to see if you are sufficiently privileged to run this command."
    c.switch [:f, :force]
        
    c.desc "Print out all the commands to stderr as they run"
    c.default_value true
    c.switch [:v, :verbose]
      
    c.desc "Don't prompt for any user input"
    c.default_value false
    c.switch [:q, :quiet]
      
    c.action do |global_options,options,args|
      require 'highline/import'
      
      # Ensure there's a logged in user
      Conjur::Authn.connect

      unless options[:force] || api.global_privilege_permitted?('elevate')
        $stderr.puts [
          "You must have 'elevate' privilege to bootstrap Conjur.",
          "If are performing a first-time bootstrap of Conjur, you should login as the 'admin' user",
          "using the admin password you selected when you ran 'evoke configure master'.",
          "",
          "If you have run 'conjur bootstrap' before, using CLI version 4.30.0 or later, the 'elevate'",
          "privilege is available to all members of the security_admin group."
          ].join("\n")
        exit_now! "Insufficient privileges to run 'bootstrap'."
      end

      saved_log = Conjur.log
      Conjur.log = $stderr if options[:verbose]
            
      unless options[:force]
        api = self.api.with_privilege('elevate')
        self.api = api
      end
      
      api.bootstrap BootstrapListener.new
      
      unless options[:quiet]
        security_admin = api.group('security_admin')
        security_administrators = security_admin.role.members.select{|m| m.member.roleid.split(':')[1..-1] != [ 'user', 'admin'] }
        $stderr.puts "Current 'security_admin' members are : #{security_administrators.map{|m| m.member.roleid.split(':', 3)[1..-1].join(':')}.sort.join(', ')}" unless security_administrators.blank?
        created_user = nil
        if security_administrators.empty? || agree("Create a new security_admin? (answer 'y' or 'yes'):")
          username = ask("Enter #{security_administrators.empty? ? 'your' : 'the'} username:")
          password = prompt_for_password
          begin
            # Don't echo the new admin user's password
            Conjur.log = nil
            $stderr.puts "Creating user '#{username}'"
            created_user = user = api.create_user(username, password: password)
          ensure
            Conjur.log = saved_log
          end
          Conjur::API.new_from_key(user.login, password).user(user.login).resource.give_to security_admin
          $stderr.puts "User created"
          $stderr.puts "Making '#{username}' a member and admin of group 'security_admin'"
          security_admin.add_member user, admin_option: true
          $stderr.puts "Adminship granted"
        end
        
        if created_user && agree("Login as user '#{created_user.login}'? (answer 'y' or 'yes'):")
          Conjur::Authn.fetch_credentials(username: created_user.login, password: created_user.api_key)
          $stderr.puts "Logged in as '#{created_user.login}'"
        end
      end
    end
  end
end
