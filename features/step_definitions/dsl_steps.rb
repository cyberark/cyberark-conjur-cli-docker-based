When(/^I use script context:$/) do |context|
  @context = JSON.parse context
end

When(/^I run script:$/) do |script|
  require 'conjur/dsl/runner'
  @runner = Conjur::DSL::Runner.new(script)
  @runner.context = @context if @context
  @runner.execute
end

Then(/^the model should contain "(.*?)" "(.*?)"$/) do |kind, id|
  @mock_api.thing(kind, id).should_not be_nil
end
Then(/^the model should contain "(.*?)" \/(.*?)\/$/) do |kind, id|
  @mock_api.thing_like(kind, Regexp.new(id)).should_not be_nil
end
Then(/^the "(.*?)" "(.*?)" should be owned by "(.*?)"$/) do |kind, id, owner|
  step "the model should contain \"#{kind}\" \"#{id}\""
  if kind == 'role' || kind == 'resource'
    @mock_api.thing(kind, id).acting_as.should == owner
  else
    @mock_api.thing(kind, id).ownerid.should == owner
  end
end

Then(/^the "(.*?)" "(.*?)" should not have an owner$/) do |kind, id|
  step "the model should contain \"#{kind}\" \"#{id}\""
  @mock_api.thing(kind, id).ownerid.should be_nil
end

Then(/^"(.*?)" can "(.*?)" "(.*?)"( with grant option)?$/) do |role, privilege, resource, grant_option|
  resource = @mock_api.thing(:resource, resource)
  permission = resource.permissions.find do |p|
    p.privilege == privilege && p.role == role && p.grant_option == !grant_option.nil?
  end
  raise "#{role} cannot #{privilege} #{resource.id} with#{grant_option ? "" : "out"} grant_option" unless permission
end

Then(/^the context should contain "(.*?)"$/) do |key|
  @runner.context.should have_key(key.to_s)
end

Then(/^the context "(.*?)" should be "(.*?)"$/) do |key, value|
  @runner.context[key].should == value
end

Then(/^the context "(.*?)" should contain "(.*?)" item$/) do |key, key_count|
  step "the context should contain \"#{key}\""
  expect(@runner.context[key].length).to eq key_count.to_i
end

