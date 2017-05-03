Feature: Annotate a resource

  Background:
    Given I load the policy:
    """
    - !resource
      kind: food
      id: bacon
      annotations:
        preparation-style: crispy
    """
  
  Scenario: Annotations are stored and returned when the resource is displayed
    When I successfully run `conjur show food:bacon`
    And the JSON at "annotations" should have 1 entry
    And the JSON at "annotations/0/name" should be "preparation-style"
    And the JSON at "annotations/0/value" should be "crispy"
  
  Scenario: Annotations are searchable
    When I successfully run `conjur list -k food -s "crispy"`
    Then the JSON should have 1 entry
    And the JSON at "0/annotations/preparation-style" should be "crispy"
