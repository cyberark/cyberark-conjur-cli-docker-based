Feature: Populate variable with values

  Background:
    Given I successfully run `conjur variable create $ns/secret initialvalue` 

  Scenario: Value provided via command-line parameter
    When I run `conjur variable values add $ns/secret secretvalue`
    Then the output should contain "Value added"
   
  Scenario: Value provided via stdin
    When I run `bash -c 'echo "secretvalue" | conjur variable values add $ns/secret'`
    Then the output should contain "Value added"
