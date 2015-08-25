Feature: List members of a role

  Scenario: Role members list is initally just the creator of the role
    When I successfully run `conjur role create job:$ns/chef`
    And I successfully run `conjur role members job:$ns/chef`
    Then the JSON should have 1 entries

  Scenario: Members can be added to the role by granting them the role
    When I successfully run `conjur role create job:$ns/chef`
    And I successfully run `conjur user create alice@$ns`
    And I successfully run `conjur role grant_to job:$ns/chef user:alice@$ns`
    And I successfully run `conjur role members job:$ns/chef`
    Then the JSON should have 2 entries

  Scenario: Members list is not expanded transitively
    When I successfully run `conjur role create job:$ns/chef`
    And I successfully run `conjur group create $ns/cooks`
    And I successfully run `conjur user create alice@$ns`
    And I successfully run `conjur group members add $ns/cooks user:alice@$ns`
    When I successfully run `conjur role grant_to job:$ns/chef group:$ns/cooks`
    And I successfully run `conjur role members job:$ns/chef`
    Then the JSON should have 2 entries
    