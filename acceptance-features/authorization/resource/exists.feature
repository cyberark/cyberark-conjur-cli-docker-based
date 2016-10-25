Feature: Test the existence of a resource

  Scenario: Existing resources can be detected
    Given I load the policy:
    """
    - !resource
      kind: food
      id: bacon
    """
    And I reset the command list
    When I successfully run `conjur resource exists food:bacon`
    Then the stdout should contain exactly "true"

  Scenario: Non-existent resources are reported as such
    When I successfully run `conjur resource exists food:bacon`
    Then the stdout should contain exactly "false"
  
  Scenario: Even foreign user can check existence of a resource 
    Given I load the policy:
    """
    - !resource
      kind: food
      id: bacon

    - !user alice
    """
    And I login as "alice"
    And I reset the command list
    And I run `conjur resource exists food:bacon`
    Then the stdout should contain exactly "true"
