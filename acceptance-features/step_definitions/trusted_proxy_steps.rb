When /^I create a hostfactory token for "(.*?)" with CIDR "(.*?)"$/ do |hf, cidr|
  step %Q{I successfully run `conjur hostfactory token create --cidr #{cidr} #{hf}`}
  @hostfactory_token = JSON.parse(last_command_started.stdout)[0]['token']
end

When /^I(?: can)? use the hostfactory token from "(.*?)" to create host "(.*?)"$/ do |ip, host|
  headers['Authorization'] = %Q{Token token="#{@hostfactory_token}"}
  step %Q{I send a POST request from "#{ip}" to "/api/host_factories/hosts" with:}, table([["id"], [host]]) 
  step %Q{the response status should be "201"}
end

When /^I get the audit event for the resource "(.*?)" with action "(.*?)"$/ do |resource, action|
  # resource needs to be URL-encoded, but cucumber-api URL-encodes the
  # whole string.
  response = RestClient.get(resolve("/api/audit/resources/#{CGI.escape(resource)}"), @headers)
  @response = CucumberApi::Response.create(response)
  @headers = nil
  @body = nil
  step %Q{the response status should be "200"}

  json = JSON.parse(@response)
  @audit_event = json.find {|e| e['action'] == action}
end

Then /^the audit event should show the request from "(.*?)"$/ do |ip|
  expect(@audit_event['request']['ip']).to eq(ip)
end

When /^I create a pubkey for "(.*?)" from "(.*?)" with "(.*?)"$/ do |user, ip, key|
  steps %Q{
    Given I send "text/plain" and accept JSON
    And I set the request body to "#{key}"
    When I send a POST request from "#{ip}" to "/api/pubkeys/#{user}"
    Then the response status should be "200"
  }
  @pubkey_var = @response.get "resource_identifier"
end

When /^I get the audit event for the pubkey variable with action "(.*?)"$/ do |action|
  # Need reveal, test user doesn't have privilege to see resources
  # created by pubkeys.
  headers['X-Conjur-Privilege'] = 'reveal'
  step %Q{I get the audit event for the resource "#{@pubkey_var}" with action "#{action}"}
end
