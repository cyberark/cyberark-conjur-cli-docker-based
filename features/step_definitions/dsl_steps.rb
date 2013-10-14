When(/^I run script:$/) do |script|
  require 'conjur/dsl/runner'
  Conjur::DSL::Runner.new(script).execute
end

Then(/^the model should contain "(.*?)" "(.*?)"$/) do |kind, id|
  @mock_api.thing(kind, id).should_not be_nil
end

Then(/^the "(.*?)" "(.*?)" should be owned by "(.*?)"$/) do |kind, id, owner|
  step "the model should contain \"#{kind}\" \"#{id}\""
  @mock_api.thing(kind, id).ownerid.should == owner
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