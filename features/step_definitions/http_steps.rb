When /^I send a (GET|POST|PATCH|PUT|DELETE) request forwarded from "(.*?)" to "(.*?)"$/ do |method, ip, url|
  headers['X-Forwarded-For'] = ip
  step %Q{I send a #{method} request to "#{url}"}
end

When /^I send a (GET|POST|PATCH|PUT|DELETE) request forwarded from "(.*?)" to "(.*?)" with:$/ do |method, ip, url, params_table|
  headers['X-Forwarded-For'] = ip
  step %Q{I send a #{method} request to "#{url}" with:}, params_table
end


When /^I set the( JSON)? request body to:$/ do |is_json, body|
  step("I send and accept JSON") if is_json
  @body = body
end

When /^I set the( JSON)? request body to "(.*?)"/ do |is_json, body|
  step("I send and accept JSON") if is_json
  @body = body
end

Then /^the HTTP JSON response at "(.*?)" should be "(.*?)"$/ do |path, value|
  expect(@response.get(path)).to eq(value)
end
