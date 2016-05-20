require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command
  desc 'Trigger a sync of users/groups from LDAP to Conjur'
  command :'ldap-sync' do |cmd|
    cmd.desc 'LDAP Sync profile to use (defined in UI)'
    cmd.default_value 'default'
    cmd.flag ['p', 'profile']

    cmd.desc 'Print the actions that would be performed'
    cmd.default_value false
    cmd.switch ['dry-run']

    cmd.desc 'Output format of sync operation (text, yaml)'
    cmd.default_value 'text'
    cmd.flag ['f', 'format'], :must_match => ['text', 'yaml']

    cmd.action do |_ ,options, _|
      format = options[:format] == 'text' ? 'application/json' : 'text/yaml'
      puts options

      response = api.ldap_sync_now(options[:profile], format, options[:'dry-run'])

      if options[:format] == 'text'
        response['result']['actions'].each do |action|
          puts action
        end
      else
        puts YAML.dump(response)
      end
    end
  end
end
