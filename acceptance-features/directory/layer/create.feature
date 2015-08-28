Feature: Create a layer
  
  Scenario: Create a layer
    When I successfully run `conjur layer create $ns/test_layer`
    Then the JSON response at "id" should include "test_layer"
    And the JSON response at "hosts" should be []
  
  Scenario: Create a layer owned by the security_admin group
    When I successfully run `conjur layer create --as-group $ns/security_admin $ns/test_layer`
    Then the JSON response at "ownerid" should include "security_admin"
