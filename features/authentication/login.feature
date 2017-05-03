Feature: Login a new user

  Background:
    Given I load the policy:
    """
    - !user alice
    """

  @restore-login
  Scenario: Login a new user with a password
    When I run `conjur authn login alice` interactively
    And I type the API key for "alice"
    Then the exit status should be 0
