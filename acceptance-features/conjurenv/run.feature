Feature: Run command in an environment populated from Conjur variables

  Background: 
    Given I load the policy:
    """
    - !variable access_key
    - !variable secret_key
    """
    And I run `conjur variable values add access_key ABCDEF`
    And I run `conjur variable values add secret_key XYZQWER`
    And I reset the command list

  Scenario:
    When I run `bash -c "conjur env run --yaml '{ cloud_access_key: !var access_key , cloud_secret_key: !var secret_key }' -- env | grep CLOUD_"`
    Then the stdout should contain exactly "CLOUD_ACCESS_KEY=ABCDEF\nCLOUD_SECRET_KEY=XYZQWER"
