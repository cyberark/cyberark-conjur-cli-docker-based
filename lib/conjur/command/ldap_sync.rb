require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command
  desc 'LDAP sync management commands'
  command :'ldap-sync' do |cgrp|

    cgrp.desc 'Manage the policy used to sync Conjur and the LDAP server'
    cgrp.command :policy do |policy|

      policy.desc 'Show the current policy'
      policy.command :show do |show|

        show.desc 'LDAP Sync profile to use (defined in UI)'
        show.arg_name 'profile'
        show.flag ['p', 'profile'], default_value: 'default'

        show.action do |_,options,_|
          begin
            resp = api.ldap_sync_policy(config_name: options[:profile])
            
            if (policy = resp['policy'])
              if resp['ok']
                puts(policy)
              else
                exit_now! 'Failed creating the policy.'
              end
            else
              exit_now! resp['error']['message']
            end
          rescue RestClient::ResourceNotFound => ex
            exit_now! "LDAP sync is not supported by the server #{Conjur.configuration.appliance_url}"
          end
        end
      end
    end
  end
end
