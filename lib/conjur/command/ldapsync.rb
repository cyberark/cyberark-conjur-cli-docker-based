require 'conjur/command'

class Conjur::Command::LDAPSync < Conjur::Command

  LIST_FORMATS = %w(pretty json)

  def self.find_job_by_id args
    job_id = require_arg args, 'JOB-ID'

    if (job = api.ldap_sync_jobs.find{|j| j.id == job_id})
      job
    else
      exit_now! "No job found with ID '#{job_id}'"
    end
  end

  desc 'LDAP sync management commands'
  command :'ldap-sync' do |cgrp|

    cgrp.desc 'Manage detached LDAP sync jobs'
    cgrp.command :jobs do |jobs|

      jobs.desc 'List detached jobs'
      jobs.command :list do |cmd|

        cmd.desc "Specify output format (#{LIST_FORMATS.join(',')})"
        cmd.flag %w(f format), default_value: 'json', must_match: LIST_FORMATS

        cmd.desc 'Show only JOB ids'
        cmd.switch %w(i ids-only), default_value: false

        cmd.action do |_,options,_|
          jobs = api.ldap_sync_jobs.map(&:to_h)


          if options[:format] == 'pretty'
            require 'table_print'
            fields = [{id: {width: 38}}]

            fields.concat([:type, :state, :exclusive]) unless options[:'ids-only']

            tp jobs, *fields
          else
            jobs = jobs.map{|j| j[:id]} if options[:'ids-only']

            display(jobs)
          end

        end
      end

      jobs.desc 'Delete a detached job'
      jobs.arg_name 'JOB-ID'
      jobs.command :delete do |cmd|
        cmd.action do |_, _, args|
          find_job_by_id(args).delete
          puts "Job deleted"
        end
      end

      jobs.desc 'Show the output from a detached job'
      jobs.arg_name 'JOB-ID'
      jobs.command :output do |cmd|
        cmd.action do |_,_,args|
          find_job_by_id(args).output do |event|
            display(event)
          end
        end
      end
    end

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

        # options[:'dry-run'] is nil when dry_run should be disabled (either --no-dry-run
        # or no option given at all). It is true when --dry-run is given.
        dry_run = options[:'dry-run']
        dry_run = false if dry_run.nil?

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
