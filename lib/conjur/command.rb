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
require 'base64'

module Conjur
  class Command
    extend Conjur::IdentifierManipulation
    
    @@api = nil
    
    class << self
      attr_accessor :prefix
      
      def method_missing *a, &b
        Conjur::CLI.send *a, &b
      end

      def command name, *a, &block
        name = "#{prefix}:#{name}" if prefix
        Conjur::CLI.command(name, *a, &block)
      end

      def require_arg(args, name)
        args.shift or raise "Missing parameter: #{name}"
      end

      def assert_empty(args)
        exit_now! "Received extra command arguments" unless args.empty?
      end
      
      def api= api
        @@api = api
      end

      def api
        @@api ||= Conjur::Authn.connect
      end
      
      def current_user
        username = api.username
        kind, id = username.split('/')
        unless kind && id
          id = kind
          kind = 'user'
        end
        api.send(kind, username)
      end

      # Prevent a deprecated command from being displayed in the help output
      def hide_docs(command)
        def command.nodoc; true end
      end

      def context_option command
        command.desc "Load context from this config file, and save it when finished. The file permissions will be 0600 by default."
        command.arg_name "FILE"
        command.flag [:c, :context]
      end
      
      def highline
        require 'highline'
        @highline ||= HighLine.new($stdin,$stderr)
      end
    
      def read_till_eof(prompt = nil)
        highline.say(prompt) if prompt
        [].tap do |lines|
          loop do
            begin
              lines << highline.ask('')
            rescue EOFError
              break
            end
          end
        end.join("\n")
      end
      
      def command_options_for_list(c)
        return if c.flags.member?(:role) # avoid duplicate flags
        c.desc "Role to act as. By default, the current logged-in role is used."
        c.arg_name 'ROLE'
        c.flag [:role]
    
        c.desc "Full-text search on resource id and annotation values" 
        c.flag [:s, :search]
        
        c.desc "Maximum number of records to return"
        c.flag [:l, :limit]
        
        c.desc "Offset to start from"
        c.flag [:o, :offset]
        
        c.desc "Show only ids"
        c.switch [:i, :ids]
        
        c.desc "Show annotations in 'raw' format"
        c.switch [:r, :"raw-annotations"]
      end
      
      def command_impl_for_list(global_options, options, args)
        opts = options.slice(:search, :limit, :options, :kind) 
        opts[:acting_as] = options[:role] if options[:role]
        opts[:search]=opts[:search].gsub('-',' ') if opts[:search]
        resources = api.resources(opts)
        if options[:ids]
          puts JSON.pretty_generate(resources.map(&:id))
        else
          resources = resources.map &:attributes
          unless options[:'raw-annotations']
            resources = resources.map do |r|
              r['annotations'] = (r['annotations'] || []).inject({}) do |hash, annot|
                hash[annot['name']] = annot['value']
                hash
              end
              r
            end
          end
          puts JSON.pretty_generate resources
        end
      end
      
      def validate_privileges message, &block
        valid = begin
          yield
        rescue RestClient::Forbidden
          false
        end
        exit_now! message unless valid
      end

      def display_members(members, options)
        result = if options[:V]
          members.collect {|member|
            {
              role: member.role.id,
              member: member.member.id,
              admin_option: member.admin_option
            }
          }
        else
          members.map(&:member).map(&:id)
        end
        display result
      end

      def display(obj, options = {})
        str = if obj.respond_to?(:attributes)
          JSON.pretty_generate obj.attributes
        elsif obj.respond_to?(:id)
          obj.id
        else
          begin
            JSON.pretty_generate(obj)
          rescue JSON::GeneratorError
            obj.to_json
          end
        end
        puts str
      end

      def integer? v
        Integer(v, 10) rescue false
      end

      def prompt_for_password
        require 'highline'
        # use stderr to allow output redirection, e.g.
        # conjur user:create -p username > user.json
        hl = HighLine.new($stdin, $stderr)
    
        password = hl.ask("Enter the password (it will not be echoed): "){ |q| q.echo = false }
        if password.blank?
          if hl.agree "No password (y/n)?"
            return nil
          else
            return prompt_for_password
          end
        end

        confirmation = hl.ask("Confirm the password: "){ |q| q.echo = false }
        
        raise "Password does not match confirmation" unless password == confirmation
        
        password
      end
      
      def has_admin?(role, other_role)
        return true if role.id == other_role.id
        memberships = role.memberships.map(&:id)
        other_role.members.any? { |m| memberships.member?(m.member.id) && m.admin_option }
      rescue RestClient::Forbidden
        false
      end

    end
  end
end
