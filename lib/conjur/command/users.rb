#
# Copyright (C) 2013-2015 Conjur Inc
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

    user.desc "Update the password of the logged-in user"
    user.command :update_password do |c|
      c.desc "Password to use, otherwise you will be prompted"
      c.flag [:p,:password]

      c.action do |global_options,options,args|
        username, password = Conjur::Authn.get_credentials
        new_password = options[:password] || prompt_for_password

        Conjur::API.update_password username, password, new_password
      end
    end

    user.desc "Rotate a user's API key"
    user.command :rotate_api_key do |c|
      c.desc "Login of user whose API key we want to rotate (default: logged-in user)"
      c.flag [:user, :u]
      c.action do |_global, options, _args|
        if options.include?(:user)
          # Make sure we're not trying to rotate our own key with the user flag.
          if api.username == options[:user]
            exit_now! 'To rotate your own API key, use this command without the --user flag'
          end
          puts api.resource([ Conjur.configuration.account, "user", options[:user] ].join(":")).rotate_api_key
        else
          username, password = Conjur::Authn.read_credentials
          new_api_key = Conjur::API.rotate_api_key username, password
          # Show the new one before saving credentials so we don't lose it on failure.
          puts new_api_key
          Conjur::Authn.save_credentials username: username, password: new_api_key
        end
      end
    end
  end

  def self.format_cidr(cidr)
    case cidr
    when 'all'
      []
    when nil
      nil
    else
      cidr.split(',').each {|x| x.strip!}
    end
  end
end
