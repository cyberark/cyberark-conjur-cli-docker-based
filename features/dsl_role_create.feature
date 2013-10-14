@dsl
Feature: Creating a role

  Background:

  Scenario: Create with simple kind and id
    When I run script:
    """
role "user", "bob"
    """
    Then the model should contain "role" "cucumber:user:bob"
