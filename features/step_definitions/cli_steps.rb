When /^the command completes successfully/ do
  last_command_started.wait
  last_command_started.terminate
  expect(last_command_started.exit_status).to eq(0)
end

Then /^the output from "([^"]*)" should match \/([^\/]*)\/$/ do |cmd, expected|
  assert_matching_output(expected, output_from(cmd))
end
