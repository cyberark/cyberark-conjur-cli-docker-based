Feature: Logout the user

  Scenario: Login a new user with a password
    Given I run `conjur user create -p alice@$ns` interactively
    And I type "foobar"
    And I type "foobar"
    And the exit status should be 0
    And I keep the JSON response at "login" as "LOGIN"
    And I run `conjur authn login alice@$ns` interactively
    And I type "foobar"
    And the exit status should be 0
    And I successfully run `conjur authn logout`
    Then the stdout from "conjur authn logout" should contain exactly "Logged out\n"
