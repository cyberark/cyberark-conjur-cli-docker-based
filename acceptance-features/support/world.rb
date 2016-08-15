require 'aruba/api'
require 'conjur/api'

module ConjurCLIWorld
  include Aruba::Api
  
  attr_accessor :admin_api, :namespace, :test_user, :headers

  def last_json
    process_cmd last_command_started.stdout
  end
  
  def passwords
    @passwords ||= {}
  end
  
  def save_password username, password
    raise "Found existing password for user '#{username}'" if passwords[username]
    passwords[username] = password
  end
  
  def find_password username
    passwords[username] or raise "No password for user '#{username}'"
  end 
  
  def find_or_create_password(username)
    unless password = passwords[username] 
      password = passwords[username] = SecureRandom.hex(12)
    end
    password
  end

  def admin_role
    admin_api.current_role.role_id
  end

  def namespace
    @namespace ||= admin_api.create_variable("text/plain", "id").id
  end
  
  # Aruba's method
  def run(cmd, *args)
    # it's a thunk now so it should be returned. puts can be added back as block if we want to
    super process_cmd(cmd), *args
  end 

  # Substitute the namespace for marker $ns
  def unescape(string)
    string = super
    string.gsub("$ns", namespace)
  end
  
  def get_process(wanted)
    super wanted.gsub("$ns", namespace)
  end

  def tempfiles 
    @tempfiles||=[]
  end       

  def headers
    @headers ||= {}
  end

  def add_user_auth_header
    return if headers['Authorization']

    token = Conjur::API.authenticate(test_user.login, test_user.api_key)
    headers.merge!(
      'Authorization' => %Q{Token token="#{Base64.strict_encode64(token.to_json)}"}
    )
  end
 
  protected
  
  def process_cmd(cmd)
    cmd = cmd.dup
    cmd.gsub!("$ns", namespace)
    cmd.gsub!("$pubkeys_url", Conjur.configuration.pubkeys_url)
    
    JsonSpec.memory.each do |k,v|
      cmd.gsub!("%{#{k}}", v)
    end
    cmd
  end
end

module ConjurWorld
  def last_json
    last_stdout
  end

  def last_stdout
    raise "No commands have been run" unless last_cmd
    stdout_from last_cmd
  end

  attr_accessor :last_cmd

  def account
    Conjur::Core::API.conjur_account
  end

  def role_kind
    @role_kind ||= "cli-cukes"
  end

  def role_id_map
    @role_id_map ||= {}
  end

  def extract_filtered_graph json
    graph = JSON.parse(json.to_s)
    case graph
      when Hash then filter_hash_graph(graph)
      when Array then filter_array_graph(graph)
      else raise "WTF: graph was #{graph.class}?"
    end
  end

  def filter_hash_graph graph
    allowed = role_id_map.values
    edges = graph['graph']
    filtered = edges.select do |edge|
      allowed.member?(edge['parent']) and allowed.member?(edge['child'])
    end
    {'graph' => filtered}
  end

  def filter_array_graph graph
    allowed = role_id_map.values
    graph.select do |edge|
      edge.all?{|v| allowed.member?(v)}
    end
  end

  def graph edges
    # generate roles
    edges.flatten.uniq.each do |role_id|
      role_id_map[role_id] = expanded = expand_role_id(role_id)
      run_command "conjur role create '#{expanded}'"
    end

    # generate memberships
    edges.each do |parent, child|
      run_command "conjur role grant_to #{expand_role_id(parent)} #{expand_role_id(child)}"
    end
  end

  def run_command cmd
    step "I successfully run " + '`' + cmd + '`'
  end

  def expand_role_id role_id
    "#{account}:#{role_kind}:#{prepend_namespace role_id}"
  end

  def prepend_namespace id
    "#{namespace}-#{id}"
  end

  def expand_roles string
    role_id_map.each do |role, expanded|
      string.gsub! role, expanded
    end
    string
  end
end

World(ConjurWorld, ConjurCLIWorld)
