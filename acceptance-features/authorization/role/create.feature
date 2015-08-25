Feature: Create a Role

  Scenario: Create an abstract role
    When I run `conjur role create job:$ns/chef`
    Then the exit status should be 0
    And the output should contain "Created role"

  Scenario: Role owner has the new role listed in its memberships
    When I run `conjur role create --json --as-group $ns/security_admin job:$ns/chef`
    Then the exit status should be 0
    And I keep the JSON response at "roleid" as "ROLEID"
    And I run `conjur role memberships group:$ns/security_admin`
    And the JSON should include %{ROLEID}
