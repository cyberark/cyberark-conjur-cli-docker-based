ENV['CONJUR_APPLIANCE_URL'] ||= 'http://localhost/api/v5'
ENV['CONJUR_ACCOUNT'] ||= 'cucumber'

$username = 'admin'
$api_key = Conjur::API.login $username, 'secret'

puts "Performing acceptance tests as root-ish user '#{$username}'"

# Future Aruba
Aruba.configure do |config|
  config.exit_timeout = 15
  config.io_wait_timeout = 2
end

Before('@conjurapi-log') do
  set_env 'CONJURAPI_LOG', 'stderr'
end

Before do
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{$username}")
  step %Q(I set the environment variable "CONJUR_AUTHN_API_KEY" to "#{$api_key}")

  put_policy "bootstrap", File.read(File.expand_path('blank.yml', File.dirname(__FILE__)))
end

After do
  tempfiles.each { |tempfile| File.unlink(tempfile) unless tempfile.nil? }
end
