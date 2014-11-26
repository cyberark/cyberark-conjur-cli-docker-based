When(/^I conjurize "(.*?)"$/) do |args|
  cmd = "conjurize -f ../../features/support/host.json -c ../../features/support/conjur.conf"
  step %Q(I run `#{[ cmd, args ].compact.join(' ')}`)
end

