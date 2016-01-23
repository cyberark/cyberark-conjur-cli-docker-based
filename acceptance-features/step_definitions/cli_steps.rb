Then /^I reset the command list/ do
  aruba.command_monitor.clear
end

When /^the command completes successfully/ do
  last_command_started.wait
  last_command_started.terminate
  expect(last_command_started.exit_status).to eq(0)
end

Then /^I send the audit event:/ do |event|
  event = event.gsub('$ns',@namespace)
  step "I run `env RESTCLIENT_LOG=stderr conjur audit send` interactively"
  last_command_started.write event
  last_command_started.close_io :stdin
  step "the command completes successfully"
end

# this is step copypasted from https://github.com/cucumber/aruba/blob/master/lib/aruba/cucumber.rb#L24 
# original has typo in regexp, which is fixed here
Given(/^a file named "([^"]*?)" with: '(.*?)'$/) do |file_name, file_content|
  file_content.gsub!('$ns',@namespace)
  write_file(file_name, file_content)
end

Given(/^a file named "([^"]*?)" with namespace substitution:$/) do |file_name, file_content|
  step "a file named \"#{file_name}\" with:", file_content.gsub('$ns',@namespace)
end

Then /^it prints the path to temporary file which contains: '(.*)'$/ do |content|
  filename = last_command_started.stdout.strip
  tempfiles << filename
  actual_content = File.read(filename)
  expect(actual_content).to match(content)
end

Then /^the output from "([^"]*)" should match \/([^\/]*)\/$/ do |cmd, expected|
  assert_matching_output(expected, output_from(cmd))
end
