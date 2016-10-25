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

Given(/^I login as "(.*?)"$/) do |username|
  api_key = @api_keys['created_roles']["cucumber:user:#{username}"]['api_key']
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{username}")
  step %Q(I set the environment variable "CONJUR_AUTHN_API_KEY" to "#{api_key}")
end
