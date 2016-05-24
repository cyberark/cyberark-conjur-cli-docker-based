require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command
  desc 'LDAP sync management commands'
  command :'ldap-sync' do |cgrp|

    cgrp.desc 'Trigger a sync of users/groups from LDAP to Conjur'
    cgrp.command :now do |cmd|
      cmd.desc 'LDAP Sync profile to use (defined in UI)'
      cmd.default_value 'default'
      cmd.arg_name 'profile'
      cmd.flag ['p', 'profile']
  
      cmd.desc 'Print the actions that would be performed'
      cmd.default_value false
      cmd.switch ['dry-run']
  
      cmd.desc 'Output format of sync operation (text, yaml)'
      cmd.default_value 'text'
      cmd.arg_name 'format'
      cmd.flag ['f', 'format'], :must_match => ['text', 'yaml']
  
      cmd.action do |_ ,options, args|
        assert_empty args
        
        format = options[:format] == 'text' ? 'application/json' : 'text/yaml'
        dry_run = options[:'dry-run']
          
        $stderr.puts "Performing #{dry_run ? 'dry run ' : ''}LDAP sync"
  
        response = api.ldap_sync_now(options[:profile], format, dry_run)
  
        if options[:format] == 'text'
          puts "Messages:"
          response['events'].each do |event|
            puts [ event['timestamp'], event['severity'], event['message'] ].join("\t")
          end
          puts
          puts "Actions:"
          response['result']['actions'].each do |action|
            puts action
          end
        else
          puts response
        end
      end
    end
  end
end
