Feature: Check an environment

  Background: 
    Given I load the policy:
    """
    - !variable access_key
    - !variable secret_key
    - !variable ssh_private_key

    - !user alice

    - !permit
        role: !user alice
        privilege: execute
        resources:
        - !variable access_key
        - !variable secret_key

    """
    And I run `conjur variable values add access_key ABCDEF`
    And I run `conjur variable values add secret_key XYZQWER`
    And I run `conjur variable values add ssh_private_key PRIVATE_KEY_BODY`
    And I login as "alice"
    And I reset the command list

  Scenario: Check against permitted variables
    When I run `conjur env check --yaml '{ aws_access_key: !var access_key, aws_secret_key: !var secret_key }'`
    Then the exit status should be 0
    And the stdout should contain "aws_access_key: available\naws_secret_key: available\n"

  Scenario: Check against restricted variables
    When I run `conjur env check --yaml '{ aws_access_key: !var access_key, ssh_private_key: !var ssh_private_key }'`
    Then the exit status should be 1
    And the stdout should contain "aws_access_key: available\nssh_private_key: unavailable\n"
