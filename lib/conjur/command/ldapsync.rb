require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command
  desc 'Trigger a sync of users/groups from LDAP to Conjur'
  command :'ldap-sync' do |cmd|
    cmd.desc 'LDAP Sync profile to use (defined in UI)'
    cmd.default_value 'default'
    cmd.flag ['profile']

    cmd.desc 'Print the actions that would be performed'
    cmd.default_value false
    cmd.switch ['dry-run']

    cmd.desc 'Output format of --dry-run mode (text, yaml)'
    cmd.default_value 'text'
    cmd.flag ['format']

    cmd.action do |_ ,options, _|
      puts options
    end
  end
end
