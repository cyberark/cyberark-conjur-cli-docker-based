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


class Conjur::Command::Variables < Conjur::Command
  desc "Manage variables"
  command :variable do |var|
    var.desc "Create and store a variable"
    var.arg_name "id"
    var.command :create do |c|
      c.arg_name "mime_type"
      c.flag [:m, :"mime-type"], default_value: "text/plain"

      c.arg_name "kind"
      c.flag [:k, :"kind"], default_value: "secret"

      c.arg_name "value"
      c.desc "Initial value"
      c.flag [:v, :"value"]

      acting_as_option(c)

      c.action do |global_options,options,args|
        id = args.shift
        options[:id] = id if id

        unless id
          ActiveSupport::Deprecation.warn "id argument will be required in future releases"
        end

        mime_type = options.delete(:m)
        kind = options.delete(:k)

        options.delete(:"mime-type")
        options.delete(:"kind")

        var = api.create_variable(mime_type, kind, options)
        display(var, options)
      end
    end

    var.desc "Show a variable"
    var.arg_name "id"
    var.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'id')
        display(api.variable(id), options)
      end
    end

    var.desc "List variables"
    var.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "variable"), args
      end
    end

    var.desc "Add a value"
    var.arg_name "variable ( value | STDIN )"
    var.command :"values:add" do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'variable')
        value = args.shift || STDIN.read

        api.variable(id).add_value(value)
        puts "Value added"
      end
    end

    var.desc "Get a value"
    var.arg_name "variable"
    var.command :value do |c|
      c.desc "Version number"
      c.flag [:v, :version]

      c.action do |global_options,options,args|
        id = require_arg(args, 'variable')
        $stdout.write api.variable(id).value(options[:version])
      end
    end

    var.desc "Store value into temporary file and print out it's name"
    var.arg_name "variable"
    var.command :"to_file" do |c|
      c.desc "Version number"
      c.flag [:v, :version]
      c.action do |global_options,options,args|
        id = require_arg(args, 'variable')
        value = api.variable(id).value(options[:version])
        tempfile = `mktemp /dev/shm/conjur.XXXXXX`.strip
        File.open(tempfile,'w') { |f| f.write(value) }
        puts tempfile
      end
    end
  end
end
