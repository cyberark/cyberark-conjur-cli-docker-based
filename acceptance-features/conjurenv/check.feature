Feature: Check an environment

  Background: 
    Given I run `conjur variable create $ns/access_key ABCDEF`
    And I run `conjur variable create $ns/secret_key XYZQWER`
    And I run `conjur variable create $ns/ssh_private_key PRIVATE_KEY_BODY`
    And I run `conjur user create -p alice@$ns` interactively
    And I type "foobar"
    And I type "foobar"
    And the exit status should be 0
    And I run `conjur resource permit variable:$ns/access_key user:alice@$ns execute`
    And I run `conjur resource permit variable:$ns/secret_key user:alice@$ns execute`
    And I run `conjur authn login -u alice@$ns` interactively
    And I type "foobar"
    And the exit status should be 0


  Scenario: Check against permitted variables

    When I run `conjur env check --yaml '{ aws_access_key: !var $ns/access_key , aws_secret_key: !var $ns/secret_key }'`
    Then the exit status should be 0
    And the stdout should contain "aws_access_key: available\naws_secret_key: available\n"

  Scenario: Check against restricted variables
    When I run `conjur env check --yaml '{ aws_access_key: !var $ns/access_key , ssh_private_key: !var $ns/ssh_private_key }'`
    Then the exit status should be 1
    And the stdout should contain "aws_access_key: available\nssh_private_key: unavailable\n"
                                                 
