Feature: Show the current user

  Scenario: Show the current user
    When I successfully run `conjur authn whoami`
    Then the JSON should have "username"
