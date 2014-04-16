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


class Conjur::Command::Authn < Conjur::Command
  command :authn do |authn|
    authn.desc "Logs in and caches credentials to netrc"
    authn.long_desc <<-DESC
After successful login, subsequent commands automatically use the cached credentials. To switch users, login again using the new user credentials.
To erase credentials, use the authn:logout command.

If specified, the CAS server URL should be in the form https://<hostname>/v1.
It should be running the CAS RESTful services at the /v1 path
(or other path as specified by this argument).
    DESC
    authn.command :login do |c|
      c.arg_name 'username'
      c.flag [:u,:username]

      c.arg_name 'password'
      c.flag [:p,:password]

      c.arg_name 'CAS server'
      c.desc 'Specifies a CAS server URL to use for login'
      c.flag [:"cas-server"]

      c.action do |global_options,options,args|
        Conjur::Authn.login(options)
      end
    end

    authn.desc "Obtains an authentication token using the current logged-in user"
    authn.command :authenticate do |c|
      c.arg_name 'header'
      c.desc "Base64 encode the result and format as an HTTP Authorization header"
      c.switch [:H,:header]

      c.action do |global_options,options,args|
        token = Conjur::Authn.authenticate(options)
        if options[:header]
          puts "Authorization: Token token=\"#{Base64.strict_encode64(token.to_json)}\""
        else
          puts token
        end
      end
    end

    authn.desc "Logs out"
    authn.command :logout do |c|
      c.action do
        Conjur::Authn.delete_credentials
      end
    end

    authn.desc "Prints out the current logged in username"
    authn.command :whoami do |c|
      c.action do
        if creds = Conjur::Authn.read_credentials
          puts({account: Conjur::Core::API.conjur_account, username: creds[0]}.to_json)
        else
          exit_now! 'Not logged in.', -1
        end
      end
    end
  end
end