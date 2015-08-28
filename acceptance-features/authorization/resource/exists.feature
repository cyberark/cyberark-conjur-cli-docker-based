Feature: Test the existance of a resource

  Scenario: Existing resources can be detected
    Given I successfully run `conjur resource create food:$ns/bacon`
    When I successfully run `conjur resource exists food:$ns/bacon`
    Then the stdout from "conjur resource exists food:$ns/bacon" should contain "true"

  Scenario: Non-existant resources are reported as such
    When I successfully run `conjur resource exists food:$ns/bacon`
    Then the stdout from "conjur resource exists food:$ns/bacon" should contain "false"
  
  Scenario: Even foreign user can check existance of a resource 
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I login as a new user 
    And I run `conjur resource exists food:$ns/bacon`
    Then the stdout from "conjur resource exists food:$ns/bacon" should contain "true"
