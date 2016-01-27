Feature: Create a Host Factory
  Background:
    Given I successfully run `conjur layer create --as-group $ns/security_admin $ns/layer`

  Scenario: Create a host factory successfully
    When I successfully run `conjur hostfactory create --as-group $ns/security_admin --layer $ns/layer $ns/hostfactory`
    Then the JSON should have "deputy_api_key"

  Scenario: Host factory owner must have admin on layer
    Given I successfully run `conjur user create unprivileged@$ns`
    When I run `conjur hostfactory create --as-role user:unprivileged@$ns --layer $ns/layer $ns/hostfactory`
    Then the stderr should contain "must be an admin of layer"
    And the stdout should not contain anything
