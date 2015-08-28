Feature: Retire a host
  Background:
    When I successfully run `conjur host create $ns/host`

  Scenario: Basic retirement
    Then I successfully run `conjur host retire -d user:attic@$ns $ns/host`
