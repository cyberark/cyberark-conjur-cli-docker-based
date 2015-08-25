Feature: Add hosts to layer

  Background:
    Given I run `conjur layer create $ns/testlayer`
    And I run `conjur host create $ns.example.com`
    
  Scenario: Add host to layer
    When I successfully run `conjur layer hosts add $ns/testlayer $ns.example.com`
    Then the output should contain "Host added"
