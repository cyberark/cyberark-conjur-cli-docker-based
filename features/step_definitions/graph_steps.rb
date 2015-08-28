Given /a graph with edges/ do |table|
  graph table.raw
end

Then %r{the graph JSON should be} do |json|
  json = expand_roles json
  last_graph = extract_filtered_graph json
  expect(last_graph.to_json).to be_json_eql(json)
end

When(/^I( successfully)? run with role expansion "(.*)"$/) do |successfully, cmd|
  role_id_map.each do |role, expanded_role|
    cmd.gsub! role, expanded_role
  end
  self.last_cmd = cmd
  if successfully
    step "I successfully run `#{cmd}`"
  else
    step "I run `#{cmd}`"
  end
end