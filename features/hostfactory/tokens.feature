Feature: Host factory tokens

  Background: 
    Given I load the policy:
    """
    - !policy
      id: myapp
      body:
      - !layer
      - !host-factory
        layers: [ !layer ]
    """

  Scenario: create a host factory token
    When I successfully run `conjur hostfactory tokens create myapp`
    Then the JSON should have "0/token"

  Scenario: create a host using a token
    When I successfully run `conjur hostfactory tokens create myapp`
    And I keep the JSON response at "0/token" as "TOKEN"
    Then I use it to successfully run `conjur hostfactory hosts create %{TOKEN} host-01`
    And the JSON should have "api_key"
