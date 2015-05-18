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
    var.arg_name "id [value]"
    var.command :create do |c|
      c.arg_name "mime_type"
      c.flag [:m, :"mime-type"], default_value: 'text/plain'

      c.arg_name "kind"
      c.flag [:k, :"kind"], default_value: 'secret'

      c.arg_name "value"
      c.desc "Initial value, which may also be specified as the second command argument after the variable id"
      c.flag [:v, :"value"]

      acting_as_option c
      
      annotate_option c
      
      interactive_option c

      c.action do |global_options,options, args|
        @default_mime_type = c.flags[:m].default_value
        @default_kind = c.flags[:k].default_value
        
        id = args.shift unless args.empty?
        value = args.shift unless args.empty?
        
        exit_now! "Received conflicting value arguments" if value && options[:value]

        groupid = options[:ownerid]
        mime_type = options[:m]
        kind = options[:k]
        value ||= options[:v]
        interactive = options[:interactive] || id.blank?
        annotate = options[:annotate]
          
        exit_now! "Received --annotate option without --interactive" if annotate && !interactive
          
        annotations = {}
        # If the user asked for interactive mode, or he didn't specify and id
        # prompt for any missing options.
        if interactive
          id ||= prompt_for_id

          groupid ||= prompt_for_group

          kind = prompt_for_kind if !kind || kind == @default_kind

          mime_type = prompt_for_mime_type if !mime_type || mime_type == @default_mime_type

          annotations = prompt_for_annotations if annotate

          value ||= prompt_for_value
        end
        
        variable_options = options.slice(:ownerid)
        variable_options[:id] = id
        variable_options[:value] = value unless value.blank?
        var = api.create_variable(mime_type, kind, variable_options)
        api.resource(var).annotations.merge!(annotations) if annotations && !annotations.empty?
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

    var.desc "Decommission a variable"
    var.arg_name "id"
    var.command :retire do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'id')
        
        variable = api.variable(id)

        validate_retire_privileges variable
        
        retire_resource variable
        
        puts "Giving ownership to 'attic'"
        variable.resource.give_to api.user('attic')
        
        puts "Variable retired"
      end
    end

    var.desc "List variables"
    var.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "variable"), args
      end
    end

    var.desc "Access variable values"
    var.command :values do |values|
      values.desc "Add a value"
      values.arg_name "variable ( value | STDIN )"
      values.command :add do |c|
        c.action do |global_options,options,args|
          id = require_arg(args, 'variable')
          value = args.shift || STDIN.read

          api.variable(id).add_value(value)
          puts "Value added"
        end
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
  end

  def self.prompt_for_id
    highline.ask('Enter the id: ')
  end

  def self.prompt_for_group
    highline.ask('Enter the group: ', ->(name) { @group && @group.roleid } ) do |q|
      q.validate = ->(name) do
        name.empty? || (@group = api.group(name)).exists?
      end
      q.responses[:not_valid] = "Group '<%= @answer %>' doesn't exist, or you don't have permission to use it"
    end
  end

  def self.prompt_for_kind
    highline.ask('Enter the kind: ') {|q| q.default = @default_kind }
  end

  def self.prompt_for_mime_type
    highline.ask('Enter the MIME type: ') {|q| q.default = @default_mime_type }
  end

  def self.prompt_for_value
    read_till_eof('Enter the secret value (^D on its own line to finish):')
  end
end
