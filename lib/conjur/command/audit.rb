require 'conjur/command'
require 'active_support/ordered_hash'

class Conjur::Command
  class Audit < self
    self.prefix = 'audit'
    
    class << self
      private
      def extract_int_option(source, name, dest=nil)
        if val = source[name]
          raise "Expected an integer for #{name}, but got #{val}" unless /\d+/ =~ val
          val.to_i.tap{ |i| dest[name] = i if dest }
        end
      end
      
      def extract_audit_options options
        {}.tap do |opts|
          [:limit, :offset].each do |name|
            extract_int_option(options, name, opts)
          end
        end
      end
      
      def show_audit_events events
        puts JSON.pretty_generate(events)
      end

      def audit_feed_command kind, &block
        command kind do |c|
          c.desc "Maximum number of events to fetch"
          c.flag [:l, :limit]

          c.desc "Offset of the first event to return"
          c.flag [:o, :offset]

          c.action do |global_options, options, args|
            opts = extract_audit_options options
            show_audit_events instance_exec(args, opts, &block)
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