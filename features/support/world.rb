module CLIWorld
  def tempfiles
    @tempfiles ||= []
  end

  def api_key_of username
    role = @policy_response.created_roles["cucumber:user:#{username}"]
    if role
      role['api_key']
    else
      $conjur.resource("cucumber:user:#{username}").rotate_api_key
    end
  end

  def clear_last_json
    @last_json = nil
  end

  def last_json
    @last_json || last_command_started.stdout
  end

  def load_policy id, policy, method
    @policy_response = $conjur.load_policy id, policy, method: method
  end
end

World(CLIWorld)
