Feature: Obtain value from variable

  Background:
    And I load the policy:
    """
    - !variable secret
    """
    And I run `conjur variable values add secret secretvalue`
    And I run `conjur variable values add secret updatedvalue`
    And I reset the command list

  Scenario: Recent value is obtained by default
    When I run `conjur variable value secret`
    Then the stdout should contain exactly "updatedvalue"

  @wip  
  Scenario: Previous values can be obtained by version
    When I run `conjur variable value -v 1 secret`
    Then the stdout should contain exactly "secretvalue"
