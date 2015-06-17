class Conjur::Command
  class Audit < self
    class << self
      private
      SHORT_FORMATS = {
        'resource:check' => lambda{|e| "checked that they can #{e[:privilege]} #{e[:resource]} (#{e[:allowed]})" },
        'resource:create' => lambda{|e| "created resource #{e[:resource]} owned by #{e[:owner]}" },
        'resource:update' => lambda{|e| "gave #{e[:resource]} to #{e[:owner]}" },
        'resource:destroy' => lambda{|e| "destroyed resource #{e[:resource]}" },
        'resource:permit' => lambda{|e| "permitted #{e[:grantee]} to #{e[:privilege]} #{e[:resource]} (grant option: #{!!e[:grant_option]})" },
        'resource:deny' => lambda{|e| "denied #{e[:privilege]} from #{e[:grantee]} on #{e[:resource]}" },
        'resource:permitted_roles' => lambda{|e| "listed roles permitted to #{e[:privilege]} on #{e[:resource]}" },
        'role:check' => lambda{|e| "checked that #{e[:role] == e[:user] ? 'they' : e[:role]} can #{e[:privilege]} #{e[:resource]} (#{e[:allowed]})" },
        'role:grant' => lambda{|e| "granted role #{e[:role]} to #{e[:member]} #{e[:admin_option] ? 'with' : 'without'} admin" },
        'role:revoke' => lambda{|e| "revoked role #{e[:role]} from #{e[:member]}" },
        'role:create' => lambda{|e| "created role #{e[:role]}" },
        'audit' => lambda{ |e| 
          action_part = [ e[:facility], e[:action] ].compact.join(":")
          actor_part = e[:role] ? "by #{e[:role]}" : nil
          resource_part = e[:resource_id] ? "on #{e[:resource_id]}" : nil
          allowed_part = e.has_key?(:allowed) ? "(allowed: #{e[:allowed]})" : nil
          message_part = e[:audit_message] ? "; message: #{e[:audit_message]}" : ""
          statement = [ action_part, actor_part, resource_part, allowed_part ].compact.join(" ")
          "reported #{statement}"+ message_part
        }
      }

      def ssh_message(e)
        s = "#{e[:system_user]}"
        s << " " << (e[:allowed] ? "ran" : "attempted to run")
        s << " '" << e[:command] << "' as " << e[:target_user]
        s
      end
      
      def short_event_format e
        e.symbolize_keys!
        s = "[#{Time.parse(e[:timestamp])}]"
        s << " #{e[:user]}"
        s << " (as #{e[:acting_as]})" if e[:acting_as] != e[:user]
        if e[:facility] == 'ssh' && e[:action] == 'sudo'
          e[:audit_message] = ssh_message(e)
        end
        formatter = SHORT_FORMATS["#{e[:kind]}:#{e[:action]}"] || SHORT_FORMATS[e[:kind]]
        if formatter
          s << " " << formatter.call(e)
        else
          s << " unknown event: #{e[:kind]}:#{e[:action]}!"
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
        # Do a little song and dance to simplify testing
        extracted = options.slice :follow, :short
        [:limit, :offset].each do |name|
            extract_int_option(options, name, extracted)
        end
        if extracted[:follow] && extracted[:offset]
            exit_now! "--offset option not allowed for --follow", 1
        end
        extracted
      end
      
      def show_audit_events events, options
        events = [events] unless events.kind_of?(Array)
        # offset and limit options seem to be broken. this is a temporary workaround (should be applied on server-side eventually)
        events = events.drop(options[:offset]) if options[:offset]
        events = events.take(options[:limit]) if options[:limit]

        if options[:short]
          events.each{|e| puts short_event_format(e)}
        else
          events.each{|e| puts JSON.pretty_generate(e) }
        end
      end

      def audit_feed_command parent, kind, &block
        parent.command kind do |c|
          c.desc "Maximum number of events to fetch"
          c.flag [:l, :limit]

          c.desc "Offset of the first event to return"
          c.flag [:o, :offset]

          c.desc "Short output format"
          c.switch [:s, :short]
          
          c.desc "Follow events as they are generated"
          c.switch [:f, :follow]
          
          c.action do |global_options, options, args|
            options = extract_audit_options options 
            instance_exec(args, options, &block)
          end
        end
      end
    end

    desc "Fetch audit events"
    command :audit do |audit|
      audit.desc "Show all audit events visible to the current user"
      audit_feed_command audit, :all do |args, options|
        api.audit(options){ |es| show_audit_events es, options }
      end

      audit.desc "Show audit events related to a role"
      audit.arg_name 'role'
      audit_feed_command audit, :role do |args, options|
        id = full_resource_id(require_arg(args, "role"))
        api.audit_role(id, options){ |es| show_audit_events es, options }
      end

      audit.desc "Show audit events related to a resource"
      audit.arg_name 'resource'
      audit_feed_command audit, :resource do |args, options|
        id = full_resource_id(require_arg args, "resource")
        api.audit_resource(id, options){|es| show_audit_events es, options}
      end 
    end
  end
end
