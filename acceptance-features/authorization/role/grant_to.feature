Feature: Grant membership in a role to another role
  
  Scenario: Granting a role confers membership
    When I successfully run `conjur role create job:$ns/cooks`
    And I successfully run `conjur role create people:$ns/alice`
    And I successfully run `conjur role grant_to job:$ns/cooks people:$ns/alice`
    And I successfully run `conjur role members job:$ns/cooks`
    Then the JSON should have 2 entries
    
  Scenario: Granting a role gives the grantee permissions of the granted role
    When I successfully run `conjur role create job:$ns/cooks`
    And I successfully run `conjur role create people:$ns/alice`
    And  I successfully run `conjur resource create food:$ns/bacon`
    And I successfully run `conjur resource permit food:$ns/bacon job:$ns/cooks fry`
    And I successfully run `conjur resource check -r job:$ns/cooks food:$ns/bacon fry`
    Then the output should contain "true"
    When I successfully run `conjur resource check -r people:$ns/alice food:$ns/bacon fry`
    Then the output should contain "false"
    When I successfully run `conjur role grant_to job:$ns/cooks people:$ns/alice`
    And I successfully run `conjur resource check -r people:$ns/alice food:$ns/bacon fry`
    Then the output should contain "true"