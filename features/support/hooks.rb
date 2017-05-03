# Future Aruba
Aruba.configure do |config|
  config.exit_timeout = 15
  config.io_wait_timeout = 2
end

Transform /\$conjur_url/ do |statement|
  statement.gsub "$conjur_url", Conjur.configuration.appliance_url
end

Transform /\%\{\w+\}/ do |statement|
  JsonSpec.memory.each do |k,v|
    statement = statement.gsub("%{#{k}}", v)
  end
  statement
end

Before('@conjurapi-log') do
  set_env 'CONJURAPI_LOG', 'stderr'
end

Before do
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{$conjur.username}")
  step %Q(I set the environment variable "CONJUR_AUTHN_API_KEY" to "#{$conjur.api_key}")

  $conjur.load_policy "bootstrap", File.read(File.expand_path('blank.yml', File.dirname(__FILE__))), method: Conjur::API::POLICY_METHOD_PUT
end

After '@restore-login' do
  step %Q(I run `conjur authn login #{$conjur.username}` interactively)
  step %Q(I type "#{$conjur.api_key}")
end

After do
  tempfiles.each { |tempfile| File.unlink(tempfile) unless tempfile.nil? }
  if $netrc_file && File.read($netrc_file_path) != $netrc_file
    $stderr.puts "Restoring #{$netrc_file_path}"
    require 'fileutils'
    File.write($netrc_file_path, $netrc_file)
    FileUtils.chmod 0600, $netrc_file_path
  end
end
