#
# Copyright (C) 2013 Conjur Inc
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

class Conjur::Command::Users < Conjur::Command

  desc "Manage users"
  command :user do |user|

    user.desc "Create a new user"
    user.arg_name "login"
    user.command :create do |c|
      c.desc "Prompt for a password for the user (default: --no-password)"
      c.switch [:p,:password]

      c.desc "UID number to be associated with user (optional)"
      c.flag [:uidnumber]

      acting_as_option(c)

      interactive_option c

      c.action do |global_options,options,args|
        login = args.shift

        interactive = options[:interactive] || login.blank?

        groupid = options[:ownerid]
        uidnumber = options[:uidnumber]
        password = nil
        exit_now! "uidnumber should be integer" unless uidnumber.blank? || /\d+/ =~ uidnumber
          
        if interactive
          login ||= prompt_for_id :user, "login name"
          
          groupid ||= prompt_for_group hint: "press enter to have the user own their own record"
          uidnumber ||= prompt_for_uidnumber
          password = prompt_for_password unless options[:"no-password"]
          
          attributes = {
            "Login"    => login,
            "Owner" => groupid,
            "UID Number"  => uidnumber
          }
          attributes["Password"] = "********" unless password.blank?
          prompt_to_confirm :user, attributes
        end
        
        if options[:p] && password.blank?
          password = prompt_for_password
        end
        
        user_options = { }
        user_options[:ownerid] = groupid if groupid
        user_options[:uidnumber] = uidnumber.to_i if uidnumber
        user_options[:password] = password if password
        user = api.create_user(login, user_options)

        display user
        
        if interactive
          public_key = prompt_for_public_key
          if public_key
            api.add_public_key user.login, public_key
            puts "Public key added"
          end
        end
      end
    end

    user.desc "Show a user"
    user.arg_name "id"
    user.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'id')
        display(api.user(id), options)
      end
    end

    user.desc "Decommission a user"
    user.arg_name "id"
    user.command :retire do |c|
      retire_options c

      c.action do |global_options,options,args|
        id = require_arg(args, 'id')
        
        user = api.user(id)
        
        validate_retire_privileges user, options

        retire_resource user
        retire_role user
        give_away_resource user, options
        
        puts "User retired"
      end
    end

    user.desc "List users"
    user.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "user"), args
      end
    end

    user.desc "Update the password of the logged-in user"
    user.command :update_password do |c|
      c.desc "Password to use, otherwise you will be prompted"
      c.flag [:p,:password]

      c.action do |global_options,options,args|
        username, password = Conjur::Authn.read_credentials
        new_password = options[:password] || prompt_for_password

        Conjur::API.update_password username, password, new_password
      end
    end

    user.desc 'Rotate the API key of the logged-in user'
    user.command :rotate_api_key do |c|
      c.action do |_global, _options, _args|
        username, password = Conjur::Authn.read_credentials
        new_api_key = Conjur::API.rotate_api_key(username, password)

        # Print the new api key first, otherwise an exception
        # in save credentials could render it impossible to log in!
        puts new_api_key
        Conjur::Authn.save_credentials username: username, password: new_api_key
      end
    end

    user.desc "Update user's attributes (only uidnumber supported now)"
    user.arg_name "login" 
    user.command :update do |c|
      c.desc "UID number to be associated with user"
      c.flag [:uidnumber]
      c.action do |global_options, options, args|
        login=require_arg(args,'login')
        raise "Uidnumber should be integer" unless /\d+/ =~ options[:uidnumber]
        options[:uidnumber]=options[:uidnumber].to_i
        api.user(login).update(options)
        puts "UID set" 
      end
    end

    user.desc "Find the user by UID" 
    user.arg_name "uid" 
    user.command :uidsearch do |c| 
      c.action do |global_options, options, args| 
        uidnumber = require_arg(args,'uid')
        raise "Uidnumber should be integer" unless /\d+/ =~ uidnumber
        uidnumber=uidnumber.to_i
        display api.find_users(uidnumber: uidnumber)
      end
    end
  end
    
  def self.prompt_for_uidnumber
    prompt_for_idnumber "uid number"
  end
end
