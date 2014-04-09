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
require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Secrets < Conjur::Command
  self.prefix = :secret
  
  desc "Create and store a secret"
  arg_name "secret"
  command :create do |c|
    def c.nodoc; true end

    acting_as_option(c)

    c.action do |global_options,options,args|
      secret = args.shift or raise "Missing parameter: secret"
      display api.create_secret(secret, options), options
    end
  end

  desc "Retrieve a secret"
  arg_name "id"
  command :value do |c|
    def c.nodoc; true end
    c.action do |global_options,options,args|
      id = args.shift or raise "Missing parameter: id"
      puts api.secret(id).value
    end
  end
end