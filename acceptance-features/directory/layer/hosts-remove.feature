Feature: Remove hosts from layer

  Background:
    Given I run `conjur layer create $ns/testlayer`
    And I run `conjur host create $ns.example.com`
    And I run `conjur layer hosts add $ns/testlayer $ns.example.com`
    
  Scenario: Remove host from layer
    When I successfully run `conjur layer hosts remove $ns/testlayer $ns.example.com`
    Then the output should contain "Host removed"
