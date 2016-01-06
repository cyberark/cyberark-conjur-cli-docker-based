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
    var.arg_name "NAME VALUE"
    var.command :create do |c|
      c.arg_name "MIME-TYPE"
      c.flag [:m, :"mime-type"], default_value: 'text/plain'

      c.arg_name "KIND"
      c.flag [:k, :"kind"], default_value: 'secret'

      c.arg_name "VALUE"
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
          id ||= prompt_for_id :variable
          
          groupid ||= prompt_for_group

          kind = prompt_for_kind if !kind || kind == @default_kind
          
          mime_type = prompt_for_mime_type if mime_type.blank? || mime_type == @default_mime_type

          annotations = prompt_for_annotations if annotate

          value ||= prompt_for_value
          
          prompt_to_confirm :variable, "Id"    => id,
            "Kind"  => kind,
            "MIME type" => mime_type,
            "Owner" => groupid,
            "Value" => value
        end
        
        variable_options = { id: id }
        variable_options[:ownerid] = groupid if groupid
        variable_options[:value] = value unless value.blank?
        var = api.create_variable(mime_type, kind, variable_options)
        api.resource(var).annotations.merge!(annotations) if annotations && !annotations.empty?
        display(var, options)
      end
    end

    var.desc "Show a variable"
    var.arg_name "VARIABLE"
    var.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'VARIABLE')
        display(api.variable(id), options)
      end
    end

    var.desc "Decommission a variable"
    var.arg_name "VARIABLE"
    var.command :retire do |c|
      retire_options c
      
      c.action do |global_options,options,args|
        id = require_arg(args, 'VARIABLE')
        
        variable = api.variable(id)

        validate_retire_privileges variable, options
        
        retire_resource variable
        give_away_resource variable, options
        
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
      values.arg_name "VARIABLE VALUE"
      values.command :add do |c|
        c.action do |global_options,options,args|
          id = require_arg(args, 'VARIABLE')
          value = args.shift || STDIN.read

          api.variable(id).add_value(value)
          puts "Value added"
        end
      end
    end

    var.desc "Get a value"
    var.arg_name "VARIABLE"
    var.command :value do |c|
      c.desc "Version number"
      c.flag [:v, :version]

      c.action do |global_options,options,args|
        id = require_arg(args, 'VARIABLE')
        $stdout.write api.variable(id).value(options[:version])
      end
    end

    var.desc 'Set the expiration for a variable'
    var.command :expire do |c|
      c.arg_name "NOW"
      c.desc 'Set variable to expire immediately'
      c.switch [:n, :'now'], :negatable => false

      c.arg_name "DAYS"
      c.desc 'Set variable to expire after the given number of days'
      c.flag [:d, :'days']

      c.arg_name "MONTHS"
      c.desc 'Set variable to expire after the given number of months'
      c.flag [:m, :'months']

      c.action do |global_options, options, args|
        id = require_arg(args, 'VARIABLE')

        exit_now! 'Specify only one duration' if durations(options) > 1
        exit_now! 'Specify at least one duration' if durations(options) == 0

        now = options[:n]
        days = options[:d]
        months = options[:m]

        case
        when now.present?
          duration = 0
        when days.present?
          duration = days.to_i.days.from_now - Time.now
        when months.present?
          duration = months.to_i.months.from_now - Time.now
        end

        display api.variable(id).expire(duration)
      end
    end

    var.desc 'Display expiring variables'
    var.long_desc 'Only variables that expire within the given duration are displayed. If no duration is provided, show all visible variables that are set to expire.'
    var.command :expirations do |c|
      c.arg_name 'DAYS'
      c.desc 'Display variables that expire within the given number of days'
      c.flag [:d, :'days']

      c.arg_name 'MONTHS'
      c.desc 'Display variables that expire within the given number of months'
      c.flag [:m, :'months']

      c.action do | global_options, options, args|

        days = options[:d]
        months = options[:m]

        exit_now! 'Specify only one duration' if durations(options) > 1

        case
        when days.present?
          duration = days.to_i.days.from_now - Time.now
        when months.present?
          duration = months.to_i.months.from_now - Time.now
        end

        display api.variable_expirations(duration)
      end
    end

  end

  class << self
    def prompt_for_kind
      highline.ask('Enter the kind: ') {|q| q.default = @default_kind }
    end
    
    def prompt_for_mime_type
      highline.choose do |menu|
        menu.prompt = 'Enter the MIME type: '
        menu.choice  @default_mime_type 
        menu.choices *%w(application/json application/xml application/x-yaml application/x-pem-file)
        menu.choice "other", nil do |c|
          @highline.ask('Enter a custom mime type: ')
        end
      end
    end
    
    def prompt_for_value
      read_till_eof('Enter the secret value (^D on its own line to finish):')
    end
    
    def durations(options)
      [options[:n],options[:d],options[:m]].count {|o| o.present?}
    end
  end

end
