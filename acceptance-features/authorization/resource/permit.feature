Feature: Permit a privilege on a Resource

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

  Scenario: Permission can be granted to a new user
    And I successfully run `conjur resource show food:bacon`
    Then the JSON at "permissions" should have 1 item
    And the JSON at "permissions/0/privilege" should be "fry"
    And the JSON at "permissions/0/grant_option" should be false
