Feature: List roles which have a permission on a resource

  Background:
    Given I successfully run `conjur resource create food:$ns/bacon`

  Scenario: The owner of a resource is always listed in permitted_roles
    When I successfully run `conjur resource permitted_roles food:$ns/bacon fry`
    Then the JSON should include %{MY_ROLEID}

  Scenario: When a permission is granted to a new user, the user is listed in permitted_roles
    Given I create a new user named "alice@$ns"
    And I keep the JSON at "roleid" as "USERID"
    And I successfully run `conjur resource permit food:$ns/bacon user:alice@$ns fry`
    When I successfully run `conjur resource permitted_roles food:$ns/bacon fry`
    Then the JSON should include %{USERID}
    