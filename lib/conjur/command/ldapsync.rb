require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command

  LIST_FORMATS = %w(pretty json)

  def self.error_messages(resp)
    resp['events'].collect {|e| e['message'] if e['severity'] == 'error'}.compact
  end

  def self.show_messages(resp)
    msgs = resp['events'].each_with_object([]) do |e, arr|
      if e['severity'] == 'warn' || e['severity'] == 'error'
        arr << "\n#{e['severity'].upcase}: #{e['message']}"
      end
    end
    $stderr.puts(msgs.join("\n") + "\n\n") unless msgs.empty?
  end

  desc 'LDAP sync management commands'
  command :'ldap-sync' do |cgrp|

    cgrp.desc 'Manage the policy used to sync Conjur and the LDAP server'
    cgrp.command :policy do |policy|
      min_version policy, '4.8.0'

      policy.desc 'Show the current policy'
      policy.command :show do |show|
        min_version show, '4.8.0'
        show.desc 'LDAP Sync profile to use (defined in UI)'
        show.arg_name 'profile'
        show.flag ['p', 'profile']

        show.action do |_,options,_|

          config_name = options[:profile] || 'default'
          resp = api.ldap_sync_policy(config_name)
          
          show_messages(resp)

          if (policy = resp['policy'])
            if resp['ok']
              puts(resp['policy'])
            else
              exit_now! "Failed creating the policy."
            end
          else
            exit_now! resp['error']['message']
          end
        end
      end
    end

    # Currently hidden. It's easier to use the CLI than cURL, though,
    # so we might want to expose the profile subcommands.
    cgrp.desc 'Manage profiles for LDAP sync'
    cgrp.command :profile do |profile|
      hide_docs(profile)
      min_version profile, '4.8.0'
      
      profile.desc 'Show the profile'
      profile.command :show do |show|
        min_version show, '4.8.0'

        show.arg_name 'profile'
        show.flag ['p', 'profile']
        show.action do |_,options,_|
          display(api.ldap_sync_show_profile(options[:profile]))
        end
      end

      profile.desc 'Create or update a profile'
      profile.arg_name 'PROFILE_JSON'
      profile.long_desc %Q{Create or update the given profile.
The profile JSON may be provided in two ways:

1. As a literal (quoted) JSON string.

2. In a file, by prepending an '@' to the path to the file
}
      profile.command :update do |update|
        min_version update, '4.8.0'
        
        update.arg_name 'profile'
        update.flag ['p', 'profile']
        update.action do |_, options, args|
          config = require_arg(args, 'PROFILE_JSON')
          config = File.read(config[1..-1]) if config[0] == '@'
          display(api.ldap_sync_update_profile(options[:profile], JSON.parse(config)))
        end
      end

    end

    cgrp.desc 'Search using an LDAP sync profile'
    cgrp.command :search do |search|
      hide_docs(search)
      min_version search, '4.8.0'
      
      search.desc 'LDAP Sync profile to use (defined in UI)'
      search.arg_name 'profile'
      search.flag ['p', 'profile']
      search.action do |_,options,_|
        resp = api.ldap_sync_search(options[:profile] || 'default')
                                                                    
        show_messages(resp)

        if resp['ok']
          display resp
        else
          exit_now! "Search failed."
        end

      end
    end

  end
end
