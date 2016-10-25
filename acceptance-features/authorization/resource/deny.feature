Feature: Deny a privilege on a Resource

  Background:
    Given I load the policy:
    """
    - !resource
      kind: food
      id: bacon

    - !user alice

    - !permit
      role: !user alice
      privilege: fry
      resource: !resource
        kind: food
        id: bacon
    """

  @wip
  @announce-output
  Scenario: Once granted, privileges can be revoked
    When I apply the policy:
    """
    - !deny
      role: !user alice
      privilege: fry
      resource: !resource
        kind: food
        id: bacon
    """
    And I successfully run `conjur resource show food:bacon`
    Then the JSON at "permissions" should have 0 items
