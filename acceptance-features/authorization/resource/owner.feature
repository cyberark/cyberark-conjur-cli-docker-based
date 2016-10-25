Feature: Manage and display resource ownership.

  Background: 
    Given I load the policy:
    """
    - !user alice

    - !resource
      kind: food
      id: bacon
      owner: !user alice
    """

  Scenario: Resource owner is in the 'owner' field
    And I successfully run `conjur resource show food:bacon`
    Then the JSON at "owner" should be "cucumber:user:alice"

  Scenario: When I give a resource away, I give all permissions
    Given I login as "alice"
    And I reset the command list
    When I successfully run `conjur resource check food:bacon fry`
    Then the stdout should contain exactly "true"
