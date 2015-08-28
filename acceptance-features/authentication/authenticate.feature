Feature: Authenticate a role

  Scenario: Get a JSON token
    When I successfully run `conjur authn authenticate`
    Then the JSON should have "data"
    And the JSON should have "signature"
 
  Scenario: Get an auth token as HTTP Authorize header
    When I successfully run `conjur authn authenticate -H`
    Then the output should match /Authorization: Token token=".*"/
