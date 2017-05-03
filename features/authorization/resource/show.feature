Feature: Show a resource

  Background:
    Given I load the policy:
    """
    - !user eve

    - !user alice

    - !resource
      kind: food
      id: bacon

    - !permit
      role: !user alice
      privilege: fry
      resource: !resource
        kind: food
        id: bacon
    """
  
  Scenario: Showing a resource displays all its fields
    When I successfully run `conjur show food:bacon`
    Then the JSON should have "id"
    And the JSON should have "owner"
    And the JSON should have "permissions"
    And the JSON should have "annotations"
    
  Scenario: You can show any resource if you have a privilege on it
    Once alice has a permission to fry bacon, she can show everything
    about bacon.
  
    And I login as "alice"
    Then I successfully run `conjur show food:bacon`
