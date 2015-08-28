Feature: List memberships of a role

  Scenario: The role memberships list includes the role itself
    Given I successfully run `conjur role create job:$ns/chef`
    When I successfully run `conjur role memberships job:$ns/chef`
    Then the JSON should have 1 entries

  Scenario: Memberships can be added to a role by granting it a new role
    Given I successfully run `conjur role create job:$ns/cook`
    And I successfully run `conjur role create job:$ns/chef`
    # Cooks are chefs
    And I successfully run `conjur role grant_to job:$ns/cook job:$ns/chef`
    When I successfully run `conjur role memberships job:$ns/chef`
    # Therefore chefs are cooks and chefs
    Then the JSON should have 2 entries

  Scenario: Members list is expanded transitively
    Given I successfully run `conjur role create person:$ns/myself`
    And I successfully run `conjur role create job:$ns/cook`
    And I successfully run `conjur role create job:$ns/chef`
    # I am a chef
    And I successfully run `conjur role grant_to job:$ns/chef person:$ns/myself`
    # Chefs are cooks
    And I successfully run `conjur role grant_to job:$ns/cook job:$ns/chef`
    When I successfully run `conjur role memberships person:$ns/myself`
    # Therefore I am me, a cook, and a chef
    Then the JSON should have 3 entries
