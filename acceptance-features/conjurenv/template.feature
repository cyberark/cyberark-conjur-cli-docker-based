Feature: Embed values of Conjur variables into ERB template

  Background: 
    Given a file named "template.erb" with: 'aws credentials: [<%= conjurenv["aws_access_key"] %>, <%= conjurenv["aws_secret_key"] %>]'
    And I run `conjur variable create $ns/access_key ABCDEF`
    And I run `conjur variable create $ns/secret_key XYZQWER`
    And I reset the command list

  Scenario:
    When I run `conjur env template --yaml '{ aws_access_key: !var $ns/access_key , aws_secret_key: !var $ns/secret_key }' template.erb `
    Then it prints the path to temporary file which contains: 'aws credentials: [ABCDEF, XYZQWER]'
