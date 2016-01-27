Feature: Checking permissions on a resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I reset the command list

  Scenario: By default I check my own privilege
    In this case, I have the privilege because I own the resource
  
    When I successfully run `conjur resource check food:$ns/bacon fry`
    Then the stdout should contain exactly "true"

  Scenario: I can check the privileges of roles that I own
    When I successfully run `conjur role create job:$ns/cook`
    And I reset the command list
    And I successfully run `conjur resource check -r job:$ns/cook food:$ns/bacon fry`
    Then the stdout should contain exactly "false"
    
  Scenario: I can check the privileges of roles that I own
    When I successfully run `conjur role create job:$ns/cook`
    And I successfully run `conjur resource permit food:$ns/bacon job:$ns/cook fry`
    And I reset the command list
    And I successfully run `conjur resource check -r job:$ns/cook food:$ns/bacon fry`
    Then the stdout should contain exactly "true"
