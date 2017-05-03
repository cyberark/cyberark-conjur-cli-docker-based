Feature: Embed values of Conjur variables into ERB template

  Background: 
    Given a file named "template.erb" with: 'aws credentials: [<%= conjurenv["aws_access_key"] %>, <%= conjurenv["aws_secret_key"] %>]'
    And I load the policy:
    """
    - !variable access_key
    - !variable secret_key
    """
    And I run `conjur variable values add access_key ABCDEF`
    And I run `conjur variable values add secret_key XYZQWER`
    And I reset the command list

  Scenario:
    When I run `conjur env template --yaml '{ aws_access_key: !var access_key , aws_secret_key: !var secret_key }' template.erb `
    Then it prints the path to temporary file which contains: 'aws credentials: [ABCDEF, XYZQWER]'
