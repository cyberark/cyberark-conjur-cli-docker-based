Feature: Retire a group
  Background:
    When I successfully run `conjur group create $ns/ops`

  Scenario: Basic retirement
    Then I successfully run `conjur group retire -d user:attic@$ns $ns/ops`

  Scenario: Retiring a non-existent thing propagates the 404
    Then I run `conjur group retire -d user:attic@$ns $ns/foobar`
    Then the exit status should be 1
    And the stderr should contain "Resource Not Found"

  Scenario: A foreign user can't retire a group
    Given I login as a new user
    And I run `conjur group retire -d user:attic@$ns $ns/ops`
    Then the exit status should be 1
    And the stderr should contain "You can't administer this record"

  Scenario: Can't retire to a non-existant role
    And I run `conjur group retire -d user:foobar $ns/ops`
    Then the exit status should be 1
    And the output should match /error: Destination role/
    And the output should match /doesn't exist$/

  Scenario: I can retire a group which I've granted to another group
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur role grant_to group:$ns/ops group:$ns/admin`
    Then I successfully run `conjur group retire -d user:attic@$ns $ns/ops`

  Scenario: I can retire a group which I've given to a group that I can admin
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur resource give group:$ns/ops group:$ns/admin`
    Then I successfully run `conjur group retire -d user:attic@$ns $ns/ops`

  Scenario: I can't retire a group if I can't admin the group's role
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur role grant_to group:$ns/ops group:$ns/admin`
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur group members add -a $ns/admin alice@$ns`
    And I login as "alice@$ns"
    And I run `conjur group retire -d user:attic@$ns $ns/ops`
    Then the exit status should be 1
    And the stderr should contain "You can't administer this record"

  Scenario: I can't retire a group if I can't admin the group's record
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur role grant_to -a group:$ns/ops group:$ns/admin`
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur group members add -a $ns/admin alice@$ns`
    And I login as "alice@$ns"
    And I run `conjur group retire -d user:attic@$ns $ns/ops`
    Then the exit status should be 1
    And the stderr should contain "You don't own the record"
    