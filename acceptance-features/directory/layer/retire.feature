Feature: Retire a layer
  Background:
    When I successfully run `conjur layer create $ns/applayer`

  Scenario: Basic retirement
    Then I successfully run `conjur layer retire -d user:attic@$ns $ns/applayer`

  Scenario: Retiring a non-existent thing propagates the 404
    Then I run `conjur layer retire -d user:attic@$ns $ns/foobar`
    Then the exit status should be 1
    And the stderr should contain "Resource Not Found"

  Scenario: A foreign user can't retire a layer
    Given I login as a new user
    And I run `conjur layer retire -d user:attic@$ns $ns/applayer`
    Then the exit status should be 1
    And the stderr should contain "You can't administer this record"

  Scenario: Can't retire to a non-existant role
    And I run `conjur layer retire -d user:foobar $ns/applayer`
    Then the exit status should be 1
    And the output should match /error: Destination role/
    And the output should match /doesn't exist$/

  Scenario: I can retire a layer which I've granted to a group
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur role grant_to layer:$ns/applayer group:$ns/admin`
    Then I successfully run `conjur layer retire -d user:attic@$ns $ns/applayer`

  Scenario: I can retire a layer which I've given to a group that I can admin
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur resource give layer:$ns/applayer group:$ns/admin`
    Then I successfully run `conjur layer retire -d user:attic@$ns $ns/applayer`

  Scenario: I can't retire a layer if I can't admin the layer's role
    Given I successfully run `conjur group create $ns/admin`
    And I successfully run `conjur role grant_to layer:$ns/applayer group:$ns/admin`
    Given I create a new user named "alice@$ns"
    And I successfully run `conjur group members add -a $ns/admin alice@$ns`
    And I login as "alice@$ns"
    And I run `conjur layer retire -d user:attic@$ns $ns/applayer`
    Then the exit status should be 1
    And the stderr should contain "You can't administer this record"
