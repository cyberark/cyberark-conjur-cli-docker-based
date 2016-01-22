Feature: Run command in an environment populated from Conjur variables

  Background: 
    Given I run `conjur variable create $ns/access_key ABCDEF`
    And I run `conjur variable create $ns/secret_key XYZQWER`
    And I reset the command list

  Scenario:
    When I run `bash -c "conjur env run --yaml '{ cloud_access_key: !var $ns/access_key , cloud_secret_key: !var $ns/secret_key }' -- env | grep CLOUD_"`
    Then the stdout should contain exactly "CLOUD_ACCESS_KEY=ABCDEF\nCLOUD_SECRET_KEY=XYZQWER"
