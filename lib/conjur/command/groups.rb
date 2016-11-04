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

class Conjur::Command::Groups < Conjur::Command
  def self.assume_user_kind(role)
    if role.split(':').length == 1
      role = [ "user", role ].join(':')
    end
    role
  end
  
  desc "Manage groups"
  command :group do |group|
    group.desc "Create a new group [DEPRECATED]"
    group.command :create do |c|
      c.desc "GID number to be associated with the group (optional)"
      c.flag [:gidnumber]

      acting_as_option(c)
      interactive_option c

      c.action do |global_options,options,args|
        notify_deprecated

        id = args.shift
        
        interactive = options[:interactive] || id.blank?

        groupid = options[:ownerid]
        gidnumber = options[:gidnumber]

        if interactive
          id ||= prompt_for_id :group
          
          groupid ||= prompt_for_group
          gidnumber ||= prompt_for_gidnumber
          
          prompt_to_confirm :group, {
            "Id"    => id,
            "Owner" => groupid,
            "Gidnumber" => gidnumber
          }
        end
        
        group_options = { }
        group_options[:ownerid] = groupid if groupid
        group_options[:gidnumber] = gidnumber.to_i unless gidnumber.blank?
          
        group = api.create_group(id, group_options)
        display(group, options)
      end
    end

    group.desc "List groups"
    group.command :list do |c|
      command_options_for_list c

      c.action do |global_options, options, args|
        command_impl_for_list global_options, options.merge(kind: "group"), args
      end
    end

    group.desc "Show a group"
    group.arg_name "GROUP"
    group.command :show do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, 'GROUP')
        display(api.group(id), options)
      end
    end
    
    group.desc "Update group's attributes (eg. gidnumber) [DEPRECATED]"
    group.arg_name "GROUP"
    group.command :update do |c|
      c.desc "GID number to be associated with the group"
      c.flag [:gidnumber]
      c.action do |global_options, options, args|
        notify_deprecated

        id = require_arg(args, 'GROUP')

        options[:gidnumber] = Integer(options[:gidnumber])
        api.group(id).update(options)

        puts "GID set"
      end
    end

    group.desc "Find groups by GID"
    group.arg_name "gid"
    group.command :gidsearch do |c|
      c.action do |global_options, options, args|
        gidnumber = Integer require_arg args, 'gid'
        display api.find_groups(gidnumber: gidnumber)
      end
    end

    group.desc "Decommission a group [DEPRECATED]"
    group.arg_name "GROUP"
    group.command :retire do |c|
      retire_options c

      c.action do |global_options,options,args|
        notify_deprecated

        id = require_arg(args, 'GROUP')
        
        group = api.group(id)
        
        validate_retire_privileges group, options
        
        retire_resource group
        retire_role group
        give_away_resource group, options
        
        puts "Group retired"
      end
    end

    group.desc "Show and manage group members"
    group.command :members do |members|

      members.desc "Lists all direct members of the group. The membership list is not recursively expanded."
      members.arg_name "GROUP"
      members.command :list do |c|
        c.desc "Verbose output"
        c.switch [:V,:verbose]
        c.action do |global_options,options,args|
          group = require_arg(args, 'GROUP')
          display_members api.group(group).role.members, options
        end
      end

      members.desc "Add a new group member [DEPRECATED]"
      members.arg_name "GROUP USER"
      members.command :add do |c|
        c.desc "Also grant the admin option"
        c.switch [:a, :admin]

        # perhaps this belongs to member:remove, but then either
        # it would be possible to grant membership with member:revoke,
        # or we would need two round-trips to authz
        c.desc "Revoke the grant option if it's granted"
        c.switch [:r, :'revoke-admin']

        c.action do |global_options,options,args|
          notify_deprecated

          group = require_arg(args, 'GROUP')
          member = require_arg(args, 'USER')
          member = assume_user_kind(member)

          group = api.group(group)
          opts = nil
          message = "Membership granted"
          if options[:admin] then
            opts = { admin_option: true }
            message = "Adminship granted"
          elsif options[:'revoke-admin'] then
            opts = { admin_option: false }
            message = "Adminship revoked"
          end

          group.add_member member, opts
          puts message
        end
      end

      members.desc "Remove a group member [DEPRECATED]"
      members.arg_name "GROUP USER"
      members.command :remove do |c|
        c.action do |global_options,options,args|
          notify_deprecated

          group = require_arg(args, 'GROUP')
          member = require_arg(args, 'USER')
          member = assume_user_kind(member)

          api.group(group).remove_member member
          puts "Membership revoked"
        end
      end

    end
  end
    
  def self.prompt_for_gidnumber
    prompt_for_idnumber "gid number"
  end
end
