require "aruba/cucumber"
require "json_spec/cucumber"
require 'cucumber-api'
require 'addressable/uri'

$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

# Overwrite cucumber-api's resolve function so it will use the scheme
# and host from ENV['CONJUR_APPLIANCE_URL'] if url doesn't already
# have a host.
$orig_resolve = self.method(:resolve)
def resolve url
  # disable cucumber-api's ill-considered cache. Re-authenticate in
  # case it (cucumber-api) wiped out the headers
  $cache = {} 
  add_user_auth_header
  url = Addressable::URI.parse(url)
  unless url.host
    conjur_url = Addressable::URI.parse(Conjur.configuration.appliance_url)
    url.merge!(:scheme => conjur_url.scheme, :host => conjur_url.host)
  end
  $orig_resolve.call(url.to_s)
end
