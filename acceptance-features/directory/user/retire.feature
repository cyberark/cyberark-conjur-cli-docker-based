Feature: Retire a user
  Background:
    When I successfully run `conjur user create --as-role user:admin@$ns alice@$ns`

  Scenario: Basic retirement
    Then I successfully run `conjur user retire -d user:attic@$ns alice@$ns`
