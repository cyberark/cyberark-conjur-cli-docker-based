Feature: List roles which have a permission on a resource

  Background:
    Given I load the policy:
    """
    - !user alice

    - !resource
      kind: food
      id: bacon
      owner: !user alice
    """

  Scenario: The owner of a resource is always listed in permitted_roles
    When I successfully run `conjur resource permitted_roles food:bacon fry`
    Then the JSON should include "cucumber:user:alice"

  Scenario: When a permission is granted to a new user, the user is listed in permitted_roles
    Given I apply the policy:
    """
    - !user bob

    - !resource
      kind: food
      id: bacon

    - !permit
      role: !user bob
      privilege: fry
      resource: !resource
        kind: food
        id: bacon
    """
    When I successfully run `conjur resource permitted_roles food:bacon fry`
    Then the JSON should include "cucumber:user:bob"
