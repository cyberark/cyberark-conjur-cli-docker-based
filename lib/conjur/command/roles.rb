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

class Conjur::Command::Roles < Conjur::Command
  desc "Manage roles"
  command :role do |role|
    role.desc "Determines whether a role exists"
    role.arg_name "ROLE"
    role.command :exists do |c|
      c.desc "Output a JSON response with a single field, exists"
      c.switch "json"
      
      c.action do |global_options,options,args|
        id = full_role_id(require_arg(args, 'ROLE'))
        role = api.role(id)
        if options[:json]
          display({
            exists: role.exists?
          })
        else
          puts role.exists?
        end
      end
    end

    role.desc "Lists role memberships. The role membership list is recursively expanded."
    role.arg_name "ROLE"

    role.command :memberships do |c|
      c.desc "Whether to show system (internal) roles"
      c.switch [:s, :system]

      c.action do |global_options,options,args|
        roleid = args.shift
        role = roleid.nil? && api.current_role(Conjur.configuration.account) || api.role(full_role_id(roleid))
        memberships = role.memberships.map(&:id)
        unless options[:system]
          memberships.reject!{|id| id =~ /^.+?:@/}
        end
        display memberships
      end
    end

    role.desc "Lists all direct members of the role. The membership list is not recursively expanded."
    role.arg_name "ROLE"
    role.command :members do |c|
      c.desc "Verbose output"
      c.switch [:V,:verbose]

      c.action do |global_options,options,args|
        roleid = args.shift
        role = roleid.nil? && api.current_role(Conjur.configuration.account) || api.role(full_role_id(roleid))
        display_members role.members, options
      end
    end
  end
end
