When /^I clear the JSON response$/ do
  clear_last_json
end

When /^I reset the command list/ do
  aruba.command_monitor.clear
end
