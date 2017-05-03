Feature: Logout the user

  Background:
    Given I load the policy:
    """
    - !user alice
    """

  @restore-login
  Scenario: Login a logged-in user
    When I run `conjur authn login alice` interactively
    And I type the API key for "alice"
    Then the exit status should be 0
    And I successfully run `conjur authn logout`
    Then the stdout from "conjur authn logout" should contain exactly "Logged out\n"
