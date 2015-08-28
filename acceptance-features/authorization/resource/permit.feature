Feature: Permit a privilege on a Resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`

  Scenario: Permission can be granted to a new user
  
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns fry`
    And I successfully run `conjur resource show food:$ns/bacon`
    Then the JSON at "permissions" should have 1 item
    And the JSON at "permissions/0/privilege" should be "fry"
    And the JSON at "permissions/0/grant_option" should be false

   Scenario: When granted with "grantable" option, the grantee can grant the privilege to other roles (supported since CLI 4.10.2)
    Given I create a new user named "alice@$ns"
    And I create a new user named "bob@$ns"
    And I successfully run `conjur resource permit --grantable food:$ns/bacon user:alice@$ns fry`
    And I login as "alice@$ns"
    Then I successfully run `conjur resource permit food:$ns/bacon user:bob@$ns fry`
