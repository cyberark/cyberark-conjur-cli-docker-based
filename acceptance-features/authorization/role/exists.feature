Feature: Test existance of a role

  Scenario: A never-created role does not exist
    When I successfully run `conjur role exists --json food:$ns/nonesuch`
    Then the JSON at "exists" should be false

  Scenario: A created role does exist
    When I successfully run `conjur role create --json food:$ns/bacon`
    And I keep the JSON response at "roleid" as "ROLEID"
    And I successfully run `conjur role exists --json %{ROLEID}`
    Then the JSON at "exists" should be true

  Scenario: Even foreign user can check existance of a role 
    When I successfully run `conjur role create --json food:$ns/bacon`
    And I keep the JSON response at "roleid" as "ROLEID"
    And I login as a new user 
    And I run `conjur role exists --json %{ROLEID}`
    Then the JSON at "exists" should be true
  
