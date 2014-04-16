
module Conjur
  module DSL
    # Entry point for the Conjur DSL.
    # 
    # Methods are available in two categories: name scoping and asset building.
    class Runner
      include Conjur::IdentifierManipulation
      
      attr_reader :script, :filename, :context
      
      def initialize(script, filename = nil)
        @context = {
          "env" => Conjur.env,
          "stack" => Conjur.stack,
          "account" => Conjur.account,
          "api_keys" => {}
        }
        @script = script
        @filename = filename
        @api = nil
        @scopes = Array.new
        @owners = Array.new
        @objects = Array.new
      end
      
      # Provides a hash to export various application specific
      # asset ids (or anything else you want)
      def assets
        @context['assets'] ||= {}
      end
      
      def api
        @api ||= connect
      end
      
      def context=(context)
        @context.deep_merge! context
      end
      
      def api_keys
        @context["api_keys"]
      end
      
      def current_object
        !@objects.empty? ? @objects.last : nil
      end
      
      # Current scope, used as a path/delimited/prefix to a role or resource id.
      def current_scope
        !@scopes.empty? ? @scopes.join('/') : nil
      end
      
      # Current scope, used for user@scope.
      def current_user_scope
        current_scope ? current_scope.gsub(/[^\w]/, '-') : nil
      end
      
      def scope name = nil, &block
        if name != nil
          do_scope name, &block
        else
          current_scope
        end
      end
      
      def namespace ns = nil, &block
        if block_given?
          ns ||= context["namespace"]
          if ns.nil?
            require 'conjur/api/variables'
            ns = context["namespace"] = api.create_variable("text/plain", "namespace").id
          end
          do_scope ns, &block
          context
        else
          @scopes[0]
        end
      end
      
      def policy id, &block
        self.role "policy", id do |role|
          context["policy"] = role.identifier
          self.owns do
            self.resource "policy", id do
              scope id do
                block.call if block_given?
              end
            end
          end
        end
      end
      
      alias model namespace
      
      def execute
        args = [ script ]
        args << filename if filename
        instance_eval(*args)
      end
      
      def resource kind, id, options = {}, &block
        id = full_resource_id([kind, qualify_id(id, kind) ].join(':'))
        find_or_create :resource, id, options, &block
      end
      
      def role kind, id, options = {}, &block
        id = full_resource_id([ kind, qualify_id(id, kind) ].join(':'))
        find_or_create :role, id, options, &block
      end

      # purpose and existence of this method are unobvious for model designer 
      # just "variable" in DSL works fine through method_missing
      # is this method OBSOLETED ?
      #   https://basecamp.com/1949725/projects/4268938-api-version-4-x/todos/84972543-low-variable
      def create_variable id = nil, options = {}, &block
        options[:id] = id if id
        mime_type = options.delete(:mime_type) || 'text/plain'
        kind = options.delete(:kind) || 'secret'
        var = api.create_variable(mime_type, kind, options)
        do_object var, &block
      end
      
      def owns
        @owners.push current_object
        begin
          yield
        ensure
          @owners.pop
        end
      end
      
      protected
      
      def qualify_id id, kind
        if id[0] == "/"
          id[1..-1]
        else
          case kind.to_sym
          when :user
            [ id, current_user_scope ].compact.join('@')
          else
            [ current_scope, id ].compact.join('/')
          end
        end
      end
      
      def method_missing(sym, *args, &block)
        if create_compatible_args?(args) && api.respond_to?(sym)
          id = args[0]
          id = qualify_id(id, sym)
          find_or_create sym, id, args[1] || {}, &block
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

        # TODO: find a way to pass annotations as part of top-level options hash
        #   https://basecamp.com/1949725/projects/4268938-api-version-4-x/todos/84965324-low-dsl-design
        annotations = options.delete(:annotations)

        unless (obj = api.send(find_method, id)) && obj.exists?
          options = expand_options(options)
          obj = if create_method == :create_variable
            #NOTE: it duplicates logic of "create_variable" method above
            #   https://basecamp.com/1949725/projects/4268938-api-version-4-x/todos/84972543-low-variable
            options[:id] = id
            mime_type = options.delete(:mime_type) || annotations[:mime_type] || 'text/plain'
            kind = options.delete(:kind) || annotations[:kind] || 'secret'
            api.send(create_method, mime_type, kind, options)
          elsif [ 2, -2 ].member?(api.method(create_method).arity)
            api.send(create_method, id, options)
          else
            options[:id] = id
            api.send(create_method, options)
          end
        end
        if annotations.kind_of? Hash
          # TODO: fix API to make 'annotations' available directly on objects
          #   https://basecamp.com/1949725/projects/4268938-api-version-4-x/todos/84970444-high-support
          obj_as_resource = obj.resource
          annotations.each { |k,v| obj_as_resource.annotations[k]=v }
        end
        do_object obj, &block
      end
      
      def do_object obj, &block
        begin
          api_keys[obj.roleid] = obj.api_key if obj.api_key 
        rescue
        end
        
        @objects.push obj
        begin
          yield obj if block_given?
          obj
        ensure
          @objects.pop
        end
      end
      
      def do_scope name, &block
        return unless block_given?
        
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
