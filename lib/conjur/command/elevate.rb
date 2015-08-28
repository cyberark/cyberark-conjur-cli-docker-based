#
# Copyright (C) 2015 Conjur Inc
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

# Implement privileged modes such as 'elevate' and 'reveal'
class Conjur::Command::Elevate < Conjur::DSLCommand
  desc "Run a sub-command with elevated privileges"
  long_desc <<-DESC
If you are allowed to do this by the Conjur server, all server-side permission checks will be bypassed and any
action will be allowed.

To be able to run this command, you must have the 'elevate' privilege on the resource '!:!:conjur'.

EXAMPLE

Force retirement of a user:

$ conjur elevate user retire alice
  DESC
  command :elevate do |c|
    c.action do |global_options,options,args|
      exit_now! "Subcommand is required" if args.empty?
      
      Conjur::Command.api = api.with_privilege "elevate"
      Conjur::CLI.run args
    end
  end
  
  desc "Run a sub-command in 'reveal' mode"
  long_desc <<-DESC
If you are allowed to do this by the Conjur server, you can inspect all data in the Conjur
authorization service. For example, you can list and search for all resources, regardless of
your ownership and privileges. You can also show details on any resource, and you can perform
permission checks on any resource.

To be able to run this command, you must have the 'reveal' privilege on the resource '!:!:conjur'.

EXAMPLE

List all groups:

$ conjur reveal group list -i

  DESC
  command :reveal do |c|
    c.action do |global_options,options,args|
      exit_now! "Subcommand is required" if args.empty?
      
      Conjur::Command.api = api.with_privilege "reveal"
      Conjur::CLI.run args
    end
  end
end
