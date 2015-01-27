require 'conjur/api'
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
    graph = JSON.parse(json) if json.kind_of?(String)
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
  
  def namespace
    @namespace ||= "ns-#{Time.now.to_i}-#{rand(1 << 32)}"
  end
  
  def expand_roles string
    role_id_map.each do |role, expanded|
      string.gsub! role, expanded
    end
    string
  end
end

World(ConjurWorld)