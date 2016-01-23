Feature: Update the password of the logged-in user

  Background:
    Given I login as a new user

  Scenario: A user can update her own password
    And I run `conjur user update_password` interactively
    Then I can type and confirm a new password

  Scenario: The new password can be used to login
    And I run `conjur user update_password` interactively
    And I type and confirm a new password
    And I run `conjur authn login alice@$ns` interactively
    And I enter the password
    Then the exit status should be 0
