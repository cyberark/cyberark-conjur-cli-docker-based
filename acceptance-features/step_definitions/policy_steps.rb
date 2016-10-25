Given /^I load the policy:$/ do |policy|
  @api_keys = possum_api.put "/policies/cucumber/policy/bootstrap", policy
end

Given /^I apply the policy:$/ do |policy|
  @api_keys = possum_api.patch "/policies/cucumber/policy/bootstrap", policy
end

Given /^I add the policy:$/ do |policy|
  @api_keys = possum_api.post "/policies/cucumber/policy/bootstrap", policy
end
