Feature: Obtain value from variable

  Background:
    Given I successfully run `conjur variable create $ns/secret secretvalue` 
    And I successfully run `conjur variable values add $ns/secret updatedvalue`

  Scenario: Recent value is obtained by default
    When I run `conjur variable value $ns/secret`
    Then the output should match /updatedvalue$/
  
  Scenario: Previous values can be obtained by version
    When I run `conjur variable value -v 1 $ns/secret`
    Then the output should match /secretvalue$/
