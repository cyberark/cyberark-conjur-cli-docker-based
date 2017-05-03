Given /^I load the policy:$/ do |policy|
  load_policy 'bootstrap', policy, Conjur::API::POLICY_METHOD_PUT
end

Given /^I apply the policy:$/ do |policy|
  load_policy 'bootstrap', policy, Conjur::API::POLICY_METHOD_PATCH
end

Given /^I add the policy:$/ do |policy|
  load_policy 'bootstrap', policy, Conjur::API::POLICY_METHOD_POST
end
