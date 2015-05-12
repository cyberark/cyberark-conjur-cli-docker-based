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
  
  def self.security_admin_manager? api
    username = api.username
    user = if username.index('/')
      nil
    else
      api.user(username)
    end
    security_admin = api.group("security_admin")
    user && 
      security_admin.exists? && 
      security_admin.role.members.find{|m| m.member.roleid == user.roleid && m.admin_option} &&
      user.role.memberships.map(&:roleid).member?(security_admin.resource.ownerid)
  end

  Conjur::CLI.command :bootstrap do |c|
    c.action do |global_options,options,args|
      require 'highline/import'

      exit_now! "You must be an administrator to bootstrap Conjur" unless security_admin_manager?(api)
        
      if (security_admin = api.group("security_admin")).exists?
        puts "Group 'security_admin' exists"
      else
        puts "Creating group 'security_admin'"
        security_admin = api.create_group("security_admin")
        security_admin.resource.give_to security_admin
      end
      
      puts "Permitting group 'security_admin' to manage public keys"
      api.group("pubkeys-1.0/key-managers").add_member security_admin, admin_option: true
      
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
      
      if (attic = api.user("attic")).exists?
        puts "User 'attic' exists"
      else
        puts "Creating user 'attic'"
        attic = api.create_user("attic")
      end
      
      if created_user && agree("Login as user '#{created_user.login}'? (answer 'y' or 'yes'):")
        Conjur::Authn.fetch_credentials(username: created_user.login, password: created_user.api_key)
        puts "Logged in as '#{created_user.login}'"
      end
    end
  end
end