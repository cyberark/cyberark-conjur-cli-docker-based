Feature: List memberships of a role

  Scenario: The role memberships list includes the role itself
    Given I load the policy:
    """
    - !group cooks
    """
    When I successfully run `conjur role memberships group:cooks`
    Then the JSON should have 1 entries

  Scenario: Memberships can be added to a role by granting it a new role
    Given I load the policy:
    """
    - !group employees

    - !group cooks

    - !grant
      role: !group employees
      member: !group cooks
    """
    When I successfully run `conjur role memberships group:cooks`
    Then the JSON should have 2 entries

  Scenario: Members list is expanded transitively
    Given I load the policy:
    """
    - !user alice

    - !group employees

    - !group cooks

    - !grant
      role: !group employees
      member: !group cooks

    - !grant
      role: !group cooks
      member: !user alice
    """
    When I successfully run `conjur role memberships user:alice`
    Then the JSON should have 3 entries
