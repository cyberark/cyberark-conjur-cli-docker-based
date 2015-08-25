Feature: Retire a variable
  Background:
    Given I successfully run `conjur variable create $ns/secret the-value` 

  Scenario: Basic retirement
    Then I successfully run `conjur variable retire -d user:attic@$ns $ns/secret`

  Scenario: A foreign user can't retire a secret
    Given I login as a new user
    And I run `conjur variable retire -d user:attic@$ns $ns/secret`
    Then the exit status should be 1
    And the stderr should contain "You don't own the record"

  Scenario: I can retire a variable which I've given to a group that I can admin
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur resource give variable:$ns/secret group:$ns/admin`
    Then I successfully run `conjur variable retire -d user:attic@$ns $ns/secret`
