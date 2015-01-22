require 'conjur/api'
module ConjurWorld
  def last_json
    all_stdout
  end

  def account
    Conjur::Core::API.conjur_account
  end

  def role_kind
    @role_kind ||= "cli-cukes"
  end


  def graph edges
    # generate roles
    edges.flatten.uniq.each do |role_id|
      run_command "conjur role create '#{expand_role_id role_id}'"
    end

    # generate memberships
    edges.each do |parent, child|
      run_command "conjur role grant_to #{expand_role_id(parent)} #{expand_role_id(child)}"
    end
  end

  def run_command cmd
    step "I successfully run \"#{cmd}\""
  end

  def expand_role_id role_id
    "#{account}:#{role_kind}:#{role_id}"
  end
end

World(ConjurWorld)