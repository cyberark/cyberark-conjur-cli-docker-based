Feature: 'elevate' can be used to activate root-like privileges

  Background:
    Given I successfully run `conjur variable create $ns/secret secretvalue`
    And I create a new user named "alice@$ns"
    
  Scenario: The secret value is not accessible without 'elevate' privilege
    Given I login as "alice@$ns"
    When I run `conjur variable value $ns/secret`
    Then the exit status should be 1
  
  Scenario: 'elevate' can't be used without permission
    Given I login as "alice@$ns"
    When I run `conjur elevate variable show $ns/secret`
    Then the exit status should be 1
  
  Scenario: The secret value is accessible with 'elevate' privilege
    Given I successfully run `conjur resource permit '!:!:conjur' alice@$ns elevate`
    And I login as "alice@$ns"
    Then I successfully run `conjur elevate variable value $ns/secret`
