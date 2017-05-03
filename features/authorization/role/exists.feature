Feature: Test existence of a role

  Scenario: A never-created role does not exist
    When I successfully run `conjur role exists --json food:nonesuch`
    Then the JSON at "exists" should be false

  Scenario: A created role does exist
    Given I load the policy:
    """
    - !role
      kind: job
      id: cook
    """
    And I successfully run `conjur role exists --json job:cook`
    Then the JSON at "exists" should be true

  Scenario: Even foreign user can check existance of a role 
    Given I load the policy:
    """
    - !user alice

    - !role
      kind: job
      id: cook
    """
    And I login as "alice"
    And I run `conjur role exists --json job:cook`
    Then the JSON at "exists" should be true
