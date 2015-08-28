Feature: Deny a privilege on a Resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`

  Scenario: Once granted, privileges can be revoked
  
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns fry`
    When I successfully run `conjur resource deny food:$ns/bacon user:alice@$ns fry`
    And I successfully run `conjur resource show food:$ns/bacon`
    Then the JSON at "permissions" should have 0 items
