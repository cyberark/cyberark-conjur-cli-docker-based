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

When /^the command completes successfully/ do
  last_command_started.wait
  last_command_started.terminate
  expect(last_command_started.exit_status).to eq(0)
end

Then /^the output from "([^"]*)" should match \/([^\/]*)\/$/ do |cmd, expected|
  assert_matching_output(expected, output_from(cmd))
end
