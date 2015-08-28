Feature: Run command in an environment populated from Conjur variables

  Background: 
    Given I run `conjur variable create $ns/access_key ABCDEF`
    And I run `conjur variable create $ns/secret_key XYZQWER`

  Scenario:
    When I run `conjur env run --yaml '{ cloud_access_key: !var $ns/access_key , cloud_secret_key: !var $ns/secret_key }' -- printenv CLOUD_ACCESS_KEY CLOUD_SECRET_KEY`
    Then the stdout should contain "ABCDEF\nXYZQWER"

