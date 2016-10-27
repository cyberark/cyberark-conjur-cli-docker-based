module GliderWorld
  def tempfiles
    @tempfiles ||= []
  end

  def put_policy id, body
    submit_policy(:put, id, body)
  end

  def post_policy id, body
    submit_policy(:post, id, body)
  end

  def patch_policy id, body
    submit_policy(:patch, id, body)
  end

  def clear_last_json
    @last_json = nil
  end

  def last_json
    @last_json || last_command_started.stdout
  end

  protected

  def submit_policy method, id, body
    @api_keys = JSON.parse RestClient::Resource.new("http://localhost/api/v6", Conjur::API.new_from_key($username, $api_key).credentials) \
      ['policies'] \
      [Conjur.configuration.account] \
      ['policy'] \
      [id].send(method, body)
  end
end

World(GliderWorld)
