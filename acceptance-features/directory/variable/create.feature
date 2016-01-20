Feature: create an empty variable

  Background:
    Given I successfully run `conjur variable create $ns/secret` 

  Scenario: Variable is created and responds to metadata
    When I run `conjur variable show $ns/secret`
    Then the JSON should have "id"
    And the JSON should have "ownerid"
    And the JSON at "version_count" should be 0
  
  Scenario: Variable keeps no value
    When I run `conjur variable value $ns/secret`
    Then the exit status should be 1
