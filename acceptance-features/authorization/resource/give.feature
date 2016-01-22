Feature: Give a resource to another role

  Scenario: I can give a resource which I own to another role
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I create a new user named "alice@$ns"
    Then I successfully run `conjur resource give food:$ns/bacon user:alice@$ns`
    And I reset the command list

  Scenario: Resource owner is in the 'owner' field
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I create a new user named "alice@$ns"
    And I keep the JSON at "roleid" as "USERID"
    Then I successfully run `conjur resource give food:$ns/bacon user:alice@$ns`
    And I successfully run `conjur resource show food:$ns/bacon`
    Then the JSON at "owner" should be %{USERID}

  Scenario: When I give a resource away, I give all permissions
    Given I successfully run `conjur resource create food:$ns/bacon`
    And I create a new user named "alice@$ns"
    And I successfully run `conjur resource give food:$ns/bacon user:alice@$ns`
    And I login as "alice@$ns"
    And I reset the command list
    When I successfully run `conjur resource check food:$ns/bacon fry`
    Then the stdout should contain exactly "true"
