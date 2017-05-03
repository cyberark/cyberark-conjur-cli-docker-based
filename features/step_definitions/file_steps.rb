# this is step copypasted from https://github.com/cucumber/aruba/blob/master/lib/aruba/cucumber.rb#L24 
# original has typo in regexp, which is fixed here
Given(/^a file named "([^"]*?)" with: '(.*?)'$/) do |file_name, file_content|
  write_file(file_name, file_content)
end

Then /^it prints the path to temporary file which contains: '(.*)'$/ do |content|
  filename = last_command_started.stdout.strip
  tempfiles << filename
  actual_content = File.read(filename)
  expect(actual_content).to match(content)
end
