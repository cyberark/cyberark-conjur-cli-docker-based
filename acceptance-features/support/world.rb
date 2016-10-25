module GliderWorld
  def tempfiles
    @tempfiles ||= []
  end

  def possum_api
    require 'possum'
    @client ||= Possum::Client.new(url: "http://localhost:5000").tap do |client|
      client.instance_variable_set "@username", $username
      client.instance_variable_set "@account", 'cucumber'
      client.api_key = $api_key
    end
  end

  def clear_last_json
    @last_json = nil
  end

  def last_json
    @last_json || last_command_started.stdout
  end
end

World(GliderWorld)
