require 'conjur/command'
require 'active_support/ordered_hash'
require 'conjur/audit/follower'

class Conjur::Command
  class Audit < self
    self.prefix = 'audit'
    
    class << self
      private
      SHORT_FORMATS = {
        'resource:check' => ->(e){ "checked that they can #{e[:privilege]} #{e[:resource]} (#{e[:allowed]})" },
        'resource:create' => ->(e){ "created resource #{e[:resource_id]} owned by #{e[:owner]}" },
        'resource:update' => ->(e){ "gave #{e[:resource]} to #{e[:owner]}"},
        'resource:destroy' => ->(e){ "destroyed resource #{e[:resource]}"},
        'resource:permit' => ->(e){ "permitted #{e[:grantee]} to #{e[:privilege]} #{e[:resource]} (grant option: #{!!e[:grant_option]})" },
        'resource:deny' => ->(e){ "denied #{e[:privilege]} from #{e[:grantee]} on #{e[:resource]}" },
        'resource:permitted_roles' => ->(e){ "listed roles permitted to #{e[:permission]} on #{e[:resource]}" },
        'role:check' => -> (e){ 
          "checked that #{e[:role] == e[:conjur_user] ? 'they' : e[:role]} can #{e[:privilege]} #{e[:resource]} (#{e[:allowed]})" 
        },
        'role:grant' => -> (e){ "granted role #{e[:role]} to #{e[:member]} #{e[:admin_option] ? ' with ' : ' without '}admin"},
        'role:revoke' => -> (e){ "revoked role #{e[:role]} from #{e[:member]}" },
        'role:create' => -> (e){ "created role #{e[:role_id]}"}
      }
      
      
      def short_event_format e
        e.symbolize_keys!
        # hack: sometimes resource is a hash.  We don't want that!
        if e[:resource] && e[:resource].kind_of?(Hash)
          e[:resource] = e[:resource]['id']
        end
        s = "[#{Time.at(e[:timestamp])}] "
        s << " #{e[:conjur_user]}"
        s << " (as #{e[:conjur_role]})" if e[:conjur_role] != e[:conjur_user]
        formatter = SHORT_FORMATS["#{e[:asset]}:#{e[:action]}"]
        if formatter
          s << " " << formatter.call(e)
        else
          s << " unknown event: #{e[:asset]}:#{e[:action]}!"
        end
        s << " (failed with #{e[:error]})" if e[:error]
        s
      end
      
      def extract_int_option(source, name, dest=nil)
        if val = source[name]
          raise "Expected an integer for #{name}, but got #{val}" unless /\d+/ =~ val
          val.to_i.tap{ |i| dest[name] = i if dest }
        end
      end
      
      def extract_audit_options options
        [:limit, :offset].each do |name|
            options[name] = extract_int_option(options, name)
        end
        options
      end
      
      def show_audit_events events, options
        events.reverse!
        if options[:short]
          events.each{|e| puts short_event_format(e)}
        else
          puts JSON.pretty_generate(events)
        end
      end

      def audit_feed_command kind, &block
        command kind do |c|
          c.desc "Maximum number of events to fetch"
          c.flag [:l, :limit]

          c.desc "Offset of the first event to return"
          c.flag [:o, :offset]

          c.desc "Short output format"
          c.switch [:s, :short]
          
          c.desc "Follow events as they are generated"
          c.switch [:f, :follow]
          
          c.action do |global_options, options, args|
            extract_audit_options options
            if options[:follow]
              receiver = self
              Conjur::Audit::Follower.new do |merge_options|
                receiver.instance_exec(args, options.merge(merge_options), &block)
              end.follow do |events|
                show_audit_events events, options
              end
            else
              show_audit_events instance_exec(args, options, &block), options
            end
          end
        end
      end
    end

    
    desc "Show audit events related to a role"
    arg_name 'role?'
    audit_feed_command :role do |args, options|
      if id = args.shift 
        method_name, method_args = :audit_role, [full_resource_id(id), options]
      else
        method_name, method_args = :audit_current_role, [options]
      end
      api.send method_name, *method_args
    end
    
    desc "Show audit events related to a resource"
    arg_name 'resource'
    audit_feed_command :resource do |args, options|
      id = full_resource_id(require_arg args, "resource")
      api.audit_resource id, options
    end
  end
end