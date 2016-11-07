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
require 'conjur/command/dsl_command'

class Conjur::Command::RubyDSL < Conjur::DSLCommand
  desc "Manage Ruby DSL policies [DEPRECATED]"
  long_desc 'DEPRECATED. Declarative YML policy supercedes Ruby policy DSL.'
  command :rubydsl do |rubydsl|
    rubydsl.desc "Load a policy from Conjur DSL"
    rubydsl.long_desc <<-DESC
Loads a Conjur policy from Ruby DSL, applying particular conventions to the role and resource
ids.

The first path element of each id is the collection. Policies can be separated into collections
according to software development lifecycle. This allows you to migrate the same policy across environments.
Often-used collection names: ci, stage, and production.

The second path element of each id is the policy name and version, following the convention
policy-x.y.z, where x, y, and z are the semantic version of the policy.

Next, each policy creates a policy role and policy resource. The policy resource is used to store
annotations on the policy. The policy role becomes the owner of the owned policy assets. The
--as-group and --as-role options can be used to set the owner of the policy role. The default
owner of the policy role is the logged-in user (you), as always.
    DESC
    rubydsl.arg_name "FILE"
    rubydsl.command :load do |c|
      acting_as_option(c)
      collection_option(c)
      context_option(c)

      c.action do |_, options, args|
        collection = options[:collection]

        if collection.nil?
          run_script args, options
        else
          run_script args, options do |runner, &block|
            runner.scope collection do
              block.call
            end
          end
        end
      end
    end

    rubydsl.desc 'Decommision a policy'
    rubydsl.arg_name 'POLICY'
    rubydsl.command :retire do |c|
      retire_options c

      c.action do |global_options, options, args |
        id = "policy:#{require_arg(args, 'POLICY')}"

        # policy isn't a rolsource (yet), but we can pretend
        Policy = Struct.new(:role, :resource)
        rubydsl = Policy.new(api.role(id), api.resource(id))

        validate_retire_privileges(rubydsl, options)

        retire_resource(rubydsl)

        # The policy resource is owned by the policy role. Having the
        # policy role is what allows us to administer it. So, we have
        # to give the resource away before we can revoke the role.
        give_away_resource(rubydsl, options)

        retire_role(rubydsl)

        puts 'Policy retired'
      end
    end

  end
end
