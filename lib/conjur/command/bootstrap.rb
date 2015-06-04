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

class Conjur::Command::Bootstrap < Conjur::Command
  desc "Create initial users, groups, and permissions"
  long_desc %Q(When you launch a new Conjur master server, it contains only one login: the "admin" user. 
  The bootstrap command will finish the setup of a new Conjur system by creating other essential records.

  Actions performed by "bootstrap" include:

  * Creation of a group called "security_admin".

  * Giving the "security_admin" the power to manage public keys.

  * Creation of a user called "attic", which will be the owner of retired records.

  * Storing the "attic" user's API key in a variable called "conjur/users/attic/api-key".

  * (optional) Create a new user who will be made a member and admin of the "security_admin" group.

  * (optional) If a new user was created, login as that user.
  )
  
  # Determines whether the current logged-in user is sufficiently powerful to perform bootstrap.
  # This is currently determined by detecting whether the logged-in role:
  #
  # * Is a user
  # * Has admin privilege on the security_admin group role
  # * Is an owner of the security_admin group resource
  #
  # The admin user will always satisfy these conditions, unless they are revoked for some reason.
  # Other users created by the bootstrap command will (typically) also have these powers.
  def self.security_admin_manager? api
    username = api.username
    user = if username.index('/')
      nil
    else
      api.user(username)
    end
    security_admin = api.group("security_admin")
    memberships = user.role.memberships.map(&:roleid) if user
    
    if user
      if security_admin.exists?
        begin
          # The user has a role which is admin of the security_admin role
          # The user has the role which owns the security_admin resource
          security_admin.role.members.find{|m| memberships.member?(m.member.roleid) && m.admin_option} &&
            memberships.member?(security_admin.resource.ownerid)
        rescue RestClient::Forbidden
          false
        end
      else
        user.login == "admin"
      end
    else
      false
    end
  end

  Conjur::CLI.command :bootstrap do |c|
    c.desc "Don't perform up-front checks to see if you are sufficiently privileged to run this command."
    c.switch [:f, :force]
        
    c.action do |global_options,options,args|
      require 'highline/import'
      
      # Ensure there's a logged in user
      Conjur::Authn.connect

      force = options[:force]
      exit_now! "You must be an administrator to bootstrap Conjur" unless force || security_admin_manager?(api)
        
      if (security_admin = api.group("security_admin")).exists?
        puts "Group 'security_admin' exists"
      else
        puts "Creating group 'security_admin'"
        security_admin = api.create_group("security_admin")
      end
      
      security_admin.resource.give_to(security_admin) unless security_admin.resource.ownerid == security_admin.role.roleid
      
      key_managers = api.group("pubkeys-1.0/key-managers")
      unless security_admin.role.memberships.map(&:roleid).member?(key_managers.role.roleid)
        puts "Permitting group 'security_admin' to manage public keys"
        key_managers.add_member security_admin, admin_option: true
      end
      
      security_administrators = security_admin.role.members.select{|m| m.member.roleid.split(':')[1..-1] != [ 'user', 'admin'] }
      puts "Current 'security_admin' members are : #{security_administrators.map{|m| m.member.roleid.split(':')[-1]}.join(', ')}" unless security_administrators.blank?
      created_user = nil
      if security_administrators.empty? || agree("Create a new security_admin? (answer 'y' or 'yes'):")
        username = ask("Enter #{security_administrators.empty? ? 'your' : 'the'} username:")
        password = prompt_for_password
        puts "Creating user '#{username}'"
        created_user = user = api.create_user(username, password: password)
        Conjur::API.new_from_key(user.login, password).user(user.login).resource.give_to security_admin
        puts "User created"
        puts "Making '#{username}' a member and admin of group 'security_admin'"
        security_admin.add_member user, admin_option: true
        security_admin.resource.permit "read", user
        puts "Adminship granted"
      end
      
      attic_user_name = "attic"
      if (attic = api.user(attic_user_name)).exists?
        puts "User '#{attic_user_name}' already exists"
      else
        puts "Creating user '#{attic_user_name}' to own retired records"
        attic = api.create_user(attic_user_name)
        api.create_variable "text/plain", 
          "conjur-api-key", 
          id: "conjur/users/#{attic_user_name}/api-key", 
          value: attic.api_key,
          ownerid: security_admin.role.roleid
      end
      
      if created_user && agree("Login as user '#{created_user.login}'? (answer 'y' or 'yes'):")
        Conjur::Authn.fetch_credentials(username: created_user.login, password: created_user.api_key)
        puts "Logged in as '#{created_user.login}'"
      end
    end
  end
end