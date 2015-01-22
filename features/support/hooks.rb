require 'ostruct'

class MockAPI
  attr_reader :things
  
  def initialize
    @things = {}
  end
  
  def thing(kind, id)
    (@things[kind.to_sym] || []).find{|r| r.id == id}  
  end
  
  def thing_like(kind, id_pattern)
    (@things[kind.to_sym] || []).find{|r| id_pattern.match(r.id)}  
  end

  def create_host(options = {})
    id = options.delete(:id)
    if id
      host = thing(:host, id)
    else
      id = SecureRandom.uuid
    end
    host ||= create_thing(:host, id, options, role: true, api_key: true)
  end
  
  def create_user(id, options = {})
    thing(:user, id) || create_thing(:user, id, options, role: true, api_key: true)
  end
  
  def create_variable(mime_type, kind)
    create_thing(:user, SecureRandom.uuid, mime_type: mime_type, kind: kind)
  end
  
  def create_resource(id, options = {})
    resource(id).tap do |resource|
      resource.send(:"exists?=", true)
      populate_options resource, options
    end
  end
  
  def create_role(id, options = {})
    role(id).tap do |role|
      role.send(:"exists?=", true)
      populate_options role, options
    end
  end
  
  [ :user, :host ].each do |kind|
    define_method kind do |id|
      thing(kind, id)
    end
  end
  
  def role(id)
    raise "Role id must be a string" unless id.is_a?(String)
    thing(:role, id) || create_thing(:role, id, { exists?: false }, role: true)
  end
  
  def resource(id)
    raise "Resource id must be a string" unless id.is_a?(String)
    thing(:resource, id) || create_thing(:resource, id, exists?: false)
  end
  
  protected
  
  def create_thing(kind, id, options, kind_options = {})
    thing = OpenStruct.new(kind: kind, id: id, exists?: true)
    
    class << thing
      def permit(privilege, role, options = {})
        (self.permissions ||= []) << OpenStruct.new(privilege: privilege, role: role.id, grant_option: !!options[:grant_option])
      end
    end
    
    if kind_options[:api_key]
      thing.api_key = SecureRandom.uuid
    end
    if kind_options[:role]
      thing.roleid = id
      class << thing
        def can(privilege, resource, options = {})
          resource.permit privilege, self, options
        end
      end
    end
    
    populate_options(thing, options)
    
    store_thing kind, thing
    
    thing
  end
  
  def populate_options(thing, options)
    options.each do |k,v|
      thing.send("#{k}=", v)
    end
  end
  
  def store_thing(kind, thing)
    (things[kind] ||= []) << thing
  end
end

Before("@dsl") do
  puts "Using MockAPI"
  puts "Using account 'cucumber'"
  
  require 'conjur/api'
  require 'conjur/config'
  require 'conjur/dsl/runner'
  
  Conjur.stub(:env).and_return "ci"
  Conjur.stub(:stack).and_return "ci"
  Conjur.stub(:account).and_return "cucumber"

  Conjur::Core::API.stub(:conjur_account).and_return 'cucumber'
  @mock_api ||= MockAPI.new
  Conjur::DSL::Runner.any_instance.stub(:api).and_return @mock_api
end

Before('@real-api') do
  cfg = File.absolute_path("#{File.dirname __FILE__}/../../.conjurrc")
  puts "cfg_path = #{cfg}"
  puts "contents = #{File.read(cfg)}"
  Conjur::Config.load cfg
  Conjur::Config.apply
end
