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
require 'conjur/api'
require 'conjur/complete'

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

RSpec::Core::DSL.change_global_dsl do
  def describe_conjurize *argv, &block
    describe *argv do
      let(:command) { Conjur::Conjurize }
      let(:invoke) do
        command.go!
      end
      before {
        require 'methadone'
        
        option_parser = OptionParser.new
        expect(option_parser).to receive(:parse!).with(no_args) do |*args|
          option_parser.parse! argv
        end
        allow(option_parser).to receive(:parse!).and_call_original
        option_parser_proxy = nil
        expect(Conjur::Conjurize).to receive(:opts) do |*args|
          option_parser_proxy ||= Methadone::OptionParserProxy.new(option_parser, command.options)
        end
      }
      instance_eval &block
    end
  end
end
