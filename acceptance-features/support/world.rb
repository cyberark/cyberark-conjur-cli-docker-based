require 'aruba/api'
require 'conjur/api'

module ConjurCLIWorld
  include Aruba::Api
  
  def last_json
    stdout_from(@last_cmd)
  end
  
  def find_or_create_password(username)
    @passwords ||= {}
    unless password = @passwords[username] 
      password = @passwords[username] = SecureRandom.hex(12)
    end
    password
  end

  def namespace
    @namespace or raise "@namespace is not initialized"
  end
  
  # Aruba's method
  def run(cmd, *args)
    # it's a thunk now so it should be returned. puts can be added back as block if we want to
    super process_cmd(cmd), *args

    #puts stderr_from(cmd)
    #puts stdout_from(cmd)
  end 

  def stderr_from(cmd)
    super process_cmd(cmd)
  end
  def stdout_from(cmd)
    super process_cmd(cmd)
  end 
  def output_from(cmd)
    super process_cmd(cmd)
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
 
  protected
  
  def process_cmd(cmd)
    cmd = cmd.dup
    cmd.gsub!("$ns", namespace)
    cmd.gsub!("$pubkeys_url", Conjur.configuration.pubkeys_url)
    
    @last_cmd = cmd
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
