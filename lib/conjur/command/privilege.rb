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

# Implement privileged modes such as 'sudo' and 'reveal'
class Conjur::Command::Privilege < Conjur::DSLCommand
  desc "Run a sub-command in privileged mode"
  long_desc <<-DESC
Conjur supports the granting of global privileges to roles (typically, groups). These privileges are:

* sudo - bypasses server-side permission checks and allows any action

* reveal - bypasses server-side permission checks on operations which list and show data

This command can be used to activate a privileged mode, which must of course be actually held by the
current logged-in role.

EXAMPLES

Force retirement of a user:

$ conjur privilege sudo user retire alice
  

List all groups:

$ conjur privilege reveal group list -i

  DESC
  arg_name "privilege"
  command :privilege do |c|
    c.action do |global_options,options,args|
      privilege = require_arg(args, 'privilege')
      exit_now! "Subcommand is required" if args.empty?
      
      $stderr.puts "Invoking subcommand with privilege '#{privilege}'"
      
      Conjur::Command.api = api.with_privilege privilege
      Conjur::CLI.run args
    end
  end
end
