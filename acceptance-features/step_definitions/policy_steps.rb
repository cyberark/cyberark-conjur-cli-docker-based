Given /^I load the policy:$/ do |policy|
  put_policy 'bootstrap', policy
end

Given /^I apply the policy:$/ do |policy|
  patch_policy 'bootstrap', policy
end

Given /^I add the policy:$/ do |policy|
  post_policy 'bootstrap', policy
end
