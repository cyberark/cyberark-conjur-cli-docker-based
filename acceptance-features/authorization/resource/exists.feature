Feature: Test the existence of a resource

  Scenario: Existing resources can be detected
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I reset the command list
    When I successfully run `conjur resource exists food:$ns/bacon`
    Then the stdout should contain exactly "true"

  Scenario: Non-existent resources are reported as such
    When I successfully run `conjur resource exists food:$ns/bacon`
    Then the stdout should contain exactly "false"
  
  Scenario: Even foreign user can check existence of a resource 
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I login as a new user 
    And I reset the command list
    And I run `conjur resource exists food:$ns/bacon`
    Then the stdout should contain exactly "true"
