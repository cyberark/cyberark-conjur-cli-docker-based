Feature: Grant membership in a role to another role
  
  Scenario: Granting a role confers membership
    Given I load the policy:
    """
    - !group cooks

    - !user alice

    - !grant
      role: !group cooks
      member: !user alice
    """
    And I successfully run `conjur role members group:cooks`
    Then the JSON should have 2 entries
    And the JSON should include "cucumber:user:admin"
    And the JSON should include "cucumber:user:alice"

  @wip
  Scenario: Granting a role gives the grantee permissions of the granted role
    Given I load the policy:
    """
    - !group cooks

    - !user alice

    - !resource
      kind: food
      id: bacon

    - !permit
      role: !group cooks
      privilege: fry
      resource: !resource
        kind: food
        id: bacon
    """
    And I successfully run `conjur resource check -r group:cooks food:bacon fry`
    Then the output should contain "true"
    When I successfully run `conjur resource check -r user:alice food:bacon fry`
    Then the output should contain "false"
    And I apply the policy:
    """
    - !grant
      role: !group cooks
      member: !user alice
    """
    And I successfully run `conjur resource check -r user:alice food:bacon fry`
    Then the output should contain "true"
