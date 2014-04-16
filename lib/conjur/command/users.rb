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

  def self.prompt_for_password
    # use stderr to allow output redirection, e.g.
    # conjur user:create -p username > user.json
    hl = HighLine.new($stdin, $stderr)

    password = hl.ask("Enter the password (it will not be echoed): "){ |q| q.echo = false }
    confirmation = hl.ask("Confirm the password: "){ |q| q.echo = false }
    
    raise "Password does not match confirmation" unless password == confirmation
    
    password
  end

  desc "Manage users"
  command :user do |user|

    user.desc "Create a new user"
    user.arg_name "login"
    user.command :create do |c|
      c.desc "Prompt for a password for the user (default: --no-password)"
      c.switch [:p,:password]

      acting_as_option(c)

      c.action do |global_options,options,args|
        login = require_arg(args, 'login')

        opts = options.slice(:ownerid)

        if options[:p]
          opts[:password] = prompt_for_password
        end

        display api.create_user(login, opts)
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
  end

end
