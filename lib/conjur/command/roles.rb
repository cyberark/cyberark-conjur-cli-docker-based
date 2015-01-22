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
  GRAPH_FORMATS = %w(json dot png)


  desc "Manage roles"
  command :role do |role|

    role.desc "Create a new role"
    role.arg_name "role"
    role.command :create do |c|
      acting_as_option(c)
      
      c.desc "Output a JSON response with a single field, roleid"
      c.switch "json"

      c.action do |global_options,options,args|
        id = require_arg(args, 'role')
        role = api.role(id)

        if ownerid = options.delete(:ownerid)
          options[:acting_as] = ownerid
        end

        role.create(options)
        if options[:json]
          display({
            roleid: role.roleid
          })
        else
          puts "Created role #{role.roleid}"
        end
      end
    end

    role.desc "Determines whether a role exists"
    role.arg_name "role"
    role.command :exists do |c|
      c.desc "Output a JSON response with a single field, exists"
      c.switch "json"
      
      c.action do |global_options,options,args|
        id = require_arg(args, 'role')
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
    role.arg_name "role"

    role.command :memberships do |c|
      c.desc "Whether to show system (internal) roles"
      c.switch [:s, :system]

      c.action do |global_options,options,args|
        roleid = args.shift
        role = roleid.nil? && api.current_role || api.role(roleid)
        memberships = role.all.map(&:roleid)
        unless options[:system]
          memberships.reject!{|id| id =~ /^.+?:@/}
        end
        display memberships
      end
    end

    role.desc "Lists all direct members of the role. The membership list is not recursively expanded."
    role.arg_name "role"
    role.command :members do |c|
      c.desc "Verbose output"
      c.switch [:V,:verbose]

      c.action do |global_options,options,args|
        role = args.shift || api.user(api.username).roleid
        display_members api.role(role).members, options
      end
    end

    role.desc "Grant a role to another role. You must have admin permission on the granting role."
    role.arg_name "role member"
    role.command :grant_to do |c|
      c.desc "Whether to grant with admin option"
      c.switch [:a,:admin]

      c.action do |global_options,options,args|
        id = require_arg(args, 'role')
        member = require_arg(args, 'member')
        role = api.role(id)
        grant_options = {}
        grant_options[:admin_option] = true if options[:admin]
        role.grant_to member, grant_options
        puts "Role granted"
      end
    end


    role.desc "Revoke a role from another role. You must have admin permission on the revoking role."
    role.arg_name "role member"
    role.command :revoke_from do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'role')
        member = require_arg(args, 'member')
        role = api.role(id)
        role.revoke_from member
        puts "Role revoked"
      end
    end


    role.long_desc <<-EOD
Retrieves a digraph representing the role members and memberships of one or more roles.

The --[no-]ancestors and --[no-descendants] determine whether the graph should include ancestors, descendants, or both.  Both
are included in the graph by default.

The --acting-as flag specifies, as usual, a role as which to perform the action.  The default is the role of the currently
authenticated user.  Only roles visible to this role will be included in the resulting graph.

The output is always written to the standard output, and can be one of the following forms (specified with the --format flag):

   * png: use the 'dot' command to generate a png image representing the graph.

   * dot: produce a file in a suitable format for use with the 'dot' program.

   * json [default]: output a JSON representation of the graph.

In order to generate png images, the 'dot' program must be present and on your path.  This program is usually installed
as part of the 'graphviz' package, and is available via apt-get on debian like systems and homebrew on OSX.

The JSON format is determined by the presence of the --short flag.  If the --short flag is present, the JSON will be an array of
edges, with each edge represented as an array:

  [
    [ 'parent1', 'child1' ],
    [ 'parent2', 'child2'],
    ...
  ]

If the --short flag is not present, the JSON output will be more verbose:

  {
    "graph": [
      {
        "parent": "parent1",
        "child":  "child1"
      },
      ...
    ]
  }
EOD
    
    role.desc "Describe role memberships as a digraph"
    role.arg_name "role", :multiple
    role.command :graph do |c|
      c.desc "Output formats [#{GRAPH_FORMATS}]"
      c.flag [:f,:format], default_value: 'json', must_match: GRAPH_FORMATS

      c.desc "Use a more compact JSON format"
      c.switch [:s, :short]

      c.desc "Whether to show ancestors"
      c.switch [:a, :ancestors], default_value: true

      c.desc "Whether to show descendants"
      c.switch [:d, :descendants], default_value: true

      acting_as_option(c)

      c.action do |_, options, args|
        format = options[:format].downcase.to_sym
        if options[:short] and format != :json
          $stderr.puts "WARNING: the --short option is meaningless when --format is not json"
        end

        params = options.slice(:ancestors, :descendants)
        params[:as_role] = options[:acting_as] if options.member?(:acting_as)

        graph = api.role_graph(args, params)

        output = case format
          when :json then graph.to_json(options[:short]) + "\n"
          when :png then graph.to_png
          when :dot then graph.to_dot + "\n"
          else raise "Unsupported format: #{format}" # not strictly necessary, because GLI must_match checks it,
                                                     # but might as well?
        end

        $stdout.write output
      end
    end
  end
end