Feature: Populate variable with values

  Background:
    Given I load the policy:
    """
    - !variable secret
    """
    And I run `conjur variable values add secret initialvalue`
    And I reset the command list

  Scenario: Value provided via command-line parameter
    When I run `conjur variable values add secret secretvalue`
    Then the output should contain "Value added"
   
  Scenario: Value provided via stdin
    When I run `bash -c 'echo "secretvalue" | conjur variable values add secret'`
    Then the output should contain "Value added"
