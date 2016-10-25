$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

require 'conjur/cli'
require 'conjur/api'
require 'aruba/cucumber'
require 'json_spec/cucumber'

require 'possum'

module Possum
  class Client
    def patch path, body = nil
      response = client.send(:patch, path, body)
      if response.success?
        return response.body
      else
        raise UnexpectedResponseError.new response
      end
    end    
  end
end
