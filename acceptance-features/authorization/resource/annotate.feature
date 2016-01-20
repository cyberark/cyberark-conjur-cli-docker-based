Feature: Annotate a resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`
  
  Scenario: Annotations are stored and returned when the resource is displayed
    Given I successfully run `conjur resource annotate food:$ns/bacon preparation-style crispy`
    When I successfully run `conjur resource show food:$ns/bacon`
    And the JSON at "annotations" should have 1 entry
    And the JSON at "annotations/0/name" should be "preparation-style"
    And the JSON at "annotations/0/value" should be "crispy"
    
  Scenario: Privilege is required to manage annotations
    Given I login as a new user
    And I run `conjur resource annotate food:$ns/bacon preparation-style crispy`
    Then the exit status should be 1

  Scenario: Read privilege is insufficient to manage annotations
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns read`
    And I login as "alice@$ns"
    Then I run `conjur resource annotate food:$ns/bacon preparation-style crispy`
    Then the exit status should be 1

  Scenario: Update privilege is sufficient to manage annotations
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns update`
    And I login as "alice@$ns"
    Then I successfully run `conjur resource annotate food:$ns/bacon preparation-style crispy`
  
  Scenario: Annotations are searchable
    Given I successfully run `conjur resource annotate food:$ns/bacon preparation-style crispy`
    When I successfully run `conjur resource list -k food -s "$ns crispy"`
    Then the JSON should have 1 entry
    And the JSON at "0/annotations/preparation-style" should be "crispy"
