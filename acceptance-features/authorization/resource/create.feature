Feature: Create a Resource

  Scenario: Create an abstract resource
    When I successfully run `conjur resource create food:$ns/bacon`
    Then the JSON should have "id"
    And the JSON should have "owner"
    And the JSON should have "permissions"
    And the JSON should have "annotations"

  Scenario: The resource owner has all privileges on it
    When I successfully run `conjur resource create food:$ns/bacon`
    And I reset the command list
    And I successfully run `conjur resource check food:$ns/bacon fry`
    Then the stdout should contain exactly "true"

  Scenario: A different role can be assigned as the owner of the resource
    When I successfully run `conjur role create job:$ns/chefs`
    And I successfully run `conjur resource create --as-role job:$ns/chefs food:$ns/bacon`
    And I reset the command list
    And I successfully run `conjur resource check -r job:$ns/chefs food:$ns/bacon fry`
    Then the stdout should contain exactly "true"
