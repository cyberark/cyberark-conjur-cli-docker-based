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

      def acting_as_option command
        return if command.flags.member?(:"as-group") # avoid duplicate flags
        command.arg_name 'Perform all actions as the specified Group'
        command.flag [:"as-group"]

        command.arg_name 'Perform all actions as the specified Role'
        command.flag [:"as-role"]
      end
      
      def interactive_option command
        command.arg_name 'interactive'
        command.desc 'Create variable interactively'
        command.switch [:i, :'interactive']
      end
      
      def annotate_option command
        command.arg_name 'annotate'
        command.desc 'Add variable annotations interactively'
        command.switch [:a, :annotate]
      end

      def prompt_for_annotations
        highline.say('Add annotations (a name and value for each one):')
        {}.tap do |annotations|
          until (name = highline.ask('  annotation name (press enter to quit annotations): ')).empty?
            annotations[name] = read_till_eof('  annotation value (^D on its own line to finish):')
          end
        end
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
          puts JSON.pretty_generate(resources.map(&:resourceid))
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
      
      def retire_options command
        command.arg_name 'role'
        command.desc "Specify a role to give the retired record to (default: the 'attic' user)"
        command.long_desc %Q(When retired, all a record's roles and permissions are revoked.
        
As a final step, the record is 'given' (e.g. 'conjur resource give') to a destination role.
The default role to receive the record is the user 'attic'. This option can be used to specify
an alternative destination role.)
        command.flag [:d, :"destination-role"]
      end
      
      def destination_role options
        destination = options[:"destination-role"]
        if destination
          api.role(destination)
        else
          api.user('attic')
        end
      end
      
      def validate_retire_privileges record, options
        if record.respond_to?(:role)
          memberships = current_user.role.memberships.map(&:roleid)
          validate_privileges "You can't administer this record" do
            # The current user has a role which is admin of the record's role
            record.role.members.find{|m| memberships.member?(m.member.roleid) && m.admin_option}
          end
        end
        
        validate_privileges "You don't own the record" do
          # The current user has the role which owns the record's resource
          current_user.role.member_of?(record.resource.ownerid)
        end
        
        role = destination_role(options)
        exit_now! "Destination role '#{role.roleid}' doesn't exist" unless role.exists?
      end
      
      def retire_resource obj
        obj.resource.attributes['permissions'].each do |p|
          role = api.role(p['role'])
          privilege = p['privilege']
          next if obj.respond_to?(:roleid) && role.roleid == obj.roleid && privilege == 'read'
          puts "Denying #{privilege} privilege to #{role.roleid}"
          obj.resource.deny(privilege, role)
        end
      end
        
      def retire_role obj
        members = obj.role.members
        # Move the invoking role to the end of the roles list, so that it doesn't
        # lose its permissions in the middle of this operation.
        # I'm sure there's a cleaner way to do this.
        self_member = members.select{|m| m.member.roleid == current_user.role.roleid}
        self_member.each do |m|
          members.delete m
        end
        members.concat self_member if self_member
        members.each do |r|
          member = api.role(r.member)
          puts "Revoking from role #{member.roleid}"
          obj.role.revoke_from member
        end
      end
      
      def give_away_resource obj, options
        destination = options[:"destination-role"]
        destination_role = if destination
          api.role(destination)
        else
          api.user('attic')
        end

        exit_now! "Role #{destination_role.roleid} doesn't exist" unless destination_role.exists?
        
        puts "Giving ownership to '#{destination_role.roleid}'"
        obj.resource.give_to destination_role
      end
      
      def display_members(members, options)
        result = if options[:V]
          members.collect {|member|
            {
              member: member.member.roleid,
              grantor: member.grantor.roleid,
              admin_option: member.admin_option
            }
          }
        else
          members.map(&:member).map(&:roleid)
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

      def prompt_to_confirm kind, properties
        puts
        puts "A new #{kind} will be created with the following properties:"
        puts
        properties.select{|k,v| !v.blank?}.each do |k,v|
          printf "%-10s: %s\n", k, v
        end
        puts
        
        exit(0) unless %w(yes y).member?(highline.ask("Proceed? (yes/no): ").strip.downcase)
      end
      
      def integer? v
        Integer(v, 10) rescue false
      end
    
      def prompt_for_id kind, label = 'id'
        highline.ask("Enter the #{label}: ") do |q|
          q.readline = true
          q.validate = lambda{|id|
            !id.blank? && !api.send(kind, id).exists?
          }
          q.responses[:not_valid] = "<% if @answer.blank? %>"\
              "#{label} cannot be blank<% else %>"\
              "A #{kind} called '<%= @answer %>' already exists<% end %>"
        end
      end

      def prompt_for_public_key
        public_key = highline.ask("Enter the public key (press enter to skip): ") do |q|
          q.validate = lambda{|key|
            if key.blank?
              true
            else
              validate_public_key key
            end
          }
          q.responses[:not_valid] = "Public key format is invalid; please try again"
        end
        public_key.blank? ? nil : public_key.strip
      end
    
      # http://serverfault.com/questions/453296/how-do-i-validate-a-rsa-ssh-public-key-file-id-rsa-pub
      def validate_public_key key
        if system('which ssh-keygen 2>&1 > /dev/null')
          Conjur.log.debug "Using ssh-keygen to verify the public key\n" if Conjur.log
          require 'tempfile'
          tempfile = Tempfile.new 'public_key'
          tempfile.write(key)
          tempfile.close
          `ssh-keygen -l -f #{tempfile.path}`
          $? == 0
        else
          Conjur.log.debug "ssh-keygen is not available; falling back to simple string testing\n" if Conjur.log
          # Should be a line with at least 2 components,
          # first one being the algo id and second a base64 string.
          # In principle this means:
          #   Base64.strict_decode64 key.strip[/\Assh-\w+ (\S+).*/, 1]

          # Since the pubkeys service is more strict: needs a name and
          # rejects ones with a space, instead reproduce its algorithm here.
          begin
            components = key.strip.split ' '
            Base64.strict_decode64 components[1]
            components.length == 3
          rescue NoMethodError, ArgumentError
            false
          end
        end
      end
      
      def prompt_for_group options = {}
        options[:hint] ||= "press enter to own the record yourself"
        group_ids = api.groups.map(&:id)
        
        highline.ask("Enter the group which will own the record (#{options[:hint]}): ", [ "" ] + group_ids) do |q|
          require 'readline'
          Readline.completion_append_character = ""
          Readline.completer_word_break_characters = ""
          
          q.readline = true
          q.validate = lambda{|id|
            @group = nil
            id.empty? || (@group = api.group(id)).exists?
          }
          q.responses[:not_valid] = "Group '<%= @answer %>' doesn't exist, or you don't have permission to use it"
        end
        @group ? @group.roleid : nil
      end

      def prompt_for_idnumber label
        result = highline.ask("Enter a #{label}: ") do |q|
          q.validate = lambda{|id|
            id.blank? || integer?(id)
          }
          q.responses[:not_valid] = "The #{label} must be an integer"
        end
        result.blank? ? nil : result.to_i
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
    end
  end
end
