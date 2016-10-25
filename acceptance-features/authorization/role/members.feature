Feature: List members of a role

  Scenario: Role members list is initally just the creator of the role
    Given I load the policy:
    """
    - !user alice

    - !group cooks
    """
    And I successfully run `conjur role members group:cooks`
    Then the JSON should be:
    """
    [
      "cucumber:user:admin"
    ]
    """

  @wip
  Scenario: Members can be added to the role by granting them the role
    Given I apply the policy:
    """
    - !grant
      role: !group cooks
      member: !user alice
    """
    And I successfully run `conjur role members job:cooks`
    Then the JSON should have 2 entries

  @wip
  Scenario: Members list is not expanded transitively
    Given I apply the policy:
    """
    - !group employees

    - !grant
      role: !group employees
      member: !group cooks

    - !grant
      role: !group cooks
      member: !user alice
    """
    And I successfully run `conjur role members job:cooks`
    Then the JSON should have 2 entries
    