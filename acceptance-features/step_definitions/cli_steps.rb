Transform /\$ns/ do |s|
  s.gsub('$ns', namespace)
end

Transform /\$user_role/ do |s|
  s.gsub('$user_role', test_user.role_id)
end

Transform /^table:/ do |table|
  table.tap do |t|
    t.hashes.each do |row|
      row.each do |_,v|
        v.gsub!('$ns', namespace)
        v.gsub!('$user_role', test_user.role_id)
      end
    end
  end
end


Then /^I reset the command list/ do
  aruba.command_monitor.clear
end

When /^the command completes successfully/ do
  last_command_started.wait
  last_command_started.terminate
  expect(last_command_started.exit_status).to eq(0)
end

Then /^I send the audit event:/ do |event|
  step "I run `env RESTCLIENT_LOG=stderr conjur audit send` interactively"
  last_command_started.write event
  last_command_started.close_io :stdin
  step "the command completes successfully"
end

# this is step copypasted from https://github.com/cucumber/aruba/blob/master/lib/aruba/cucumber.rb#L24 
# original has typo in regexp, which is fixed here
Given(/^a file named "([^"]*?)" with: '(.*?)'$/) do |file_name, file_content|
  write_file(file_name, file_content)
end

Given(/^a file named "([^"]*?)" with namespace substitution:$/) do |file_name, file_content|
  step "a file named \"#{file_name}\" with:", file_content
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
