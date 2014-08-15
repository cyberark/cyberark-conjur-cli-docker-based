require "rubygems"
require "bundler/setup"
require 'tempfile'
require 'ostruct'

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

shared_context "fresh config" do
  before {
    ENV.delete_if do |k,v|
      k =~ /^CONJUR_/
    end
    
    @configuration = Conjur.configuration
    Conjur.configuration = Conjur::Configuration.new
  }
  after {
    Conjur::Config.clear
    Conjur.configuration = @configuration
  }
end