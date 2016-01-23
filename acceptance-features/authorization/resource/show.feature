Feature: Show a resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I reset the command list
  
  Scenario: Showing a resource displays all its fields
    When I successfully run `conjur resource show food:$ns/bacon`
    Then the JSON should have "id"
    And the JSON should have "owner"
    And the JSON should have "permissions"
    And the JSON should have "annotations"

  Scenario: You can't show a resource on which you have no privileges
    Given I login as a new user
    And I reset the command list
    When I run `conjur resource show food:$ns/bacon`
    Then the exit status should be 1
    And the output should contain "Forbidden"
    
  Scenario: You can show any resource if you have a privilege on it
    Once alice has a permission to fry bacon, she can show everything
    about bacon.
  
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns fry`
    And I login as "alice@$ns"
    Then I successfully run `conjur resource show food:$ns/bacon`
