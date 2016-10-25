@wip
Feature: Host factory tokens

  Background:
    Given I successfully run `conjur layer create --as-group $ns/security_admin $ns/layer`
    And I successfully run `conjur hostfactory create --as-group $ns/security_admin --layer $ns/layer $ns/hostfactory`

  Scenario: create a host factory token
    When I successfully run `conjur hostfactory token create $ns/hostfactory`
    Then the JSON should have "0/token"

  Scenario: create a host using a token
    When I successfully run `conjur hostfactory token create $ns/hostfactory`
    And I keep the JSON response at "0/token" as "TOKEN"
    Then I successfully run `conjur hostfactory host create %{TOKEN} $ns/host`
    And the JSON should have "api_key"
 