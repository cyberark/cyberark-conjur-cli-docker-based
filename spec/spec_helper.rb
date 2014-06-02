require "rubygems"
require "bundler/setup"
require 'tempfile'
require 'ostruct'
require 'io/grab'

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

require "simplecov"
SimpleCov.start
  
def post_response(id, attributes = {})
  attributes[:id] = id
  
  OpenStruct.new({
    headers: { location: [ collection_url, id ].join('/') }, 
    body: attributes.to_json
  })
end

# stub parameters to be used in resource/asset tests
KIND="asset_kind"
ID="unique_id" 
ROLE='<role>'
MEMBER='<member>'
PRIVILEGE='<privilege>'
OWNER='<owner/userid>'
ACCOUNT='<core_account>'

require 'conjur/command/rspec/helpers'

ENV['CONJURRC'] = '/dev/null'

require 'conjur/cli'
