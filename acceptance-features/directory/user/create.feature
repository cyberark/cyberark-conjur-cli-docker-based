Feature: Create a User

  Scenario: Create a passwordless user
    When I successfully run `conjur user create alice-without-password@$ns`
    And the JSON should have "api_key"
 
  Scenario: Create a user with a password
    When I run `conjur user create -p alice-with-password@$ns` interactively
    And I type "foobar"
    And I type "foobar"
    Then the exit status should be 0
    And the JSON should have "api_key"

  Scenario: Create a user owned by the security_admin group
    When I successfully run `conjur user create --as-group $ns/security_admin alice-without-password@$ns`
    And I keep the JSON response at "ownerid" as "OWNERID"
    Then the output should contain "/security_admin"
 
  Scenario: Some characters are disallowed in user ids, such as /
    When I run `conjur user create alice/$ns`
    Then the exit status should be 1
    And the stderr should contain "error: 403 Forbidden"
    And the stdout should not contain anything
