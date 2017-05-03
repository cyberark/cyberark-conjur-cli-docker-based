Feature: Checking permissions on a resource

  Background:
    Given I load the policy:
    """
    - !resource
      kind: food
      id: bacon

    - !role
      kind: job
      id: cook
    """

  Scenario: By default I check my own privilege
    In this case, I have the privilege because I own the resource
  
    When I successfully run `conjur check food:bacon fry`
    Then the stdout should contain exactly "true"

  Scenario: I can check the privileges of roles that I own
    And I successfully run `conjur check -r job:cook food:bacon fry`
    Then the stdout should contain exactly "false"
    
  Scenario: I can check the privileges of roles that I own
    Given I apply the policy:
    """
    - !resource
      kind: food
      id: bacon

    - !role
      kind: job
      id: cook

    - !permit
      role: !role
        kind: job
        id: cook
      resource: !resource
        kind: food
        id: bacon
      privilege: fry
    """
    And I reset the command list
    And I successfully run `conjur check -r job:cook food:bacon fry`
    Then the stdout should contain exactly "true"
