Given(/^I login as a new user$/) do
  @username_index ||= 0
  username = %w(alice bob charles dave edward)[@username_index]
  raise "I'm out of usernames!" unless username
  @username_index += 1
  @username = "#{username}@$ns"
  step %Q(I login as new user "#{@username}")
end

Given(/^I create a new user named "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
 
  step "I successfully run `conjur user create --as-role user:admin@#{@namespace} #{username_ns}`"
  
  user_info = JSON.parse(last_command_started.stdout)
  save_password username_ns, user_info['api_key']
end

Given(/^I create a new host with id "(.*?)"$/) do |hostid|
  step "I successfully run `conjur host create #{@namespace}/monitoring/server`"
  host = JSON.parse(last_json)
  @host_id = host['id']
  @host_api_key = host['api_key']
end

Given(/^I login as the new host/) do
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "host/#{@host_id}")
  step %Q(I set the environment variable "CONJUR_AUTHN_API_KEY" to "#{@host_api_key}")
end

Given(/^I login as new user "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
  step %Q(I create a new user named "#{username_ns}")
  step %Q(I login as "#{username_ns}")
end

Given(/^I login as "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
  password = find_password(username_ns)
  
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{username_ns}")
  step %Q(I set the environment variable "CONJUR_AUTHN_API_KEY" to "#{password}")
end

Then(/^I(?: can)? type and confirm a new password/) do
  @password = SecureRandom.hex(12)
  step %Q(I type "#{@password}")
  step %Q(I type "#{@password}")
  step "the exit status should be 0"
end

When(/^I enter the password/) do
  raise "No current password" unless @password
  step %Q(I type "#{@password}")
end
