require 'conjur/identifier_manipulation'

module Conjur
  module DSL
    # Entry point for the Conjur DSL.
    # 
    # Methods are available in two categories: name scoping and asset building.
    class Runner
      include Conjur::IdentifierManipulation
      
      attr_reader :script, :filename
      
      def initialize(script, filename = nil)
        @script = script
        @filename = filename
        @api = nil
        @scopes = Array.new
        @owners = Array.new
        @objects = Array.new
      end
      
      def api
        @api ||= connect
      end
      
      def current_object
        !@objects.empty? ? @objects.last : nil
      end
      
      def current_scope
        !@scopes.empty? ? @scopes.join('/') : nil
      end
      
      def scope name = nil, &block
        if name != nil
          do_scope name, &block
        else
          current_scope
        end
      end
      
      def namespace &block
        require 'conjur/api/variables'
        ns = api.create_variable("text/plain", "namespace").id
        do_scope ns
      end
      
      alias model namespace
      
      def execute
        args = [ script ]
        args << filename if filename
        instance_eval(*args)
      end
      
      def resource kind, id, options = {}, &block
        id = full_resource_id([kind, qualify_id(id) ].join(':'))
        find_or_create :resource, id, options, &block
      end
      
      def role kind, id, options = {}, &block
        id = full_resource_id([ kind, qualify_id(id) ].join(':'))
        find_or_create :role, id, options, &block
      end
      
      def owns
        @owners.push current_object.id
        begin
          yield
        ensure
          @owners.pop
        end
      end
      
      protected
      
      def qualify_id id
        if id[0] == "/"
          id[1..-1]
        else
          [ current_scope, id ].compact.join('/')
        end
      end
      
      def method_missing(sym, *args, &block)
        if create_compatible_args?(args) && api.respond_to?(sym)
          id = qualify_id(args[0])
          find_or_create sym, id, args[1] || {}
        elsif current_object && current_object.respond_to?(sym)
          current_object.send(sym, *args, &block)
        else
          super
        end
      end
      
      def create_compatible_args?(args)
        valid_prototypes = [
          lambda { args.length == 1 },
          lambda { args.length == 2 && args[1].is_a?(Hash) }
        ]
        !valid_prototypes.find{|p| p.call}.nil?
      end
      
      def find_or_create(type, id, options, &block)
        find_method = type.to_sym
        create_method = "create_#{type}".to_sym
        unless obj = api.send(find_method, id).exists?
          options = expand_options(options)
          obj = api.send(create_method, id, options)
        end
        do_object obj, &block
      end
      
      def do_object obj, &block
        @objects.push obj
        begin
          yield obj if block_given?
          obj
        ensure
          @objects.pop
        end
      end
      
      def do_scope name, &block
        @scopes.push(name)
        begin
          yield
        ensure
          @scopes.pop
        end
      end
      
      def owner(options)
        owner = options[:owner] || @owners.last
        owner = owner.roleid if owner.respond_to?(:roleid)
        owner
      end
      
      def expand_options(opts)
        (opts || {}).tap do |options|
          if owner = owner(options)
            options[:ownerid] = owner
          end
        end
      end
      
      def connect
        require 'conjur/authn'
        Conjur::Authn.connect      
      end
    end
  end
end