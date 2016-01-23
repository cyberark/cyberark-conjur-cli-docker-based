Then /^I reset the command list/ do
  aruba.command_monitor.clear
end

Then /^I send the audit event:/ do |event|
  event = event.gsub('$ns',@namespace)
  step "I run `env RESTCLIENT_LOG=stderr conjur audit send` interactively"
  last_command_started.write event
  last_command_started.close_io :stdin
  last_command_started.wait
  step "the exit status should be 0"
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
  filename = all_output.split("\n").last
  tempfiles << filename
  actual_content=File.read(filename) rescue ""
  expect(actual_content).to match(content)
end

Then /^the output from "([^"]*)" should match \/([^\/]*)\/$/ do |cmd, expected|
  assert_matching_output(expected, output_from(cmd))
end
