@wip
Feature: Register a public key

  Background:
    Given I load the policy:
    """
    - !user alice

    - !user bob
    """
    And I successfully run `ssh-keygen -t rsa -C "laptop" -N "" -f ./id_alice`
    And I reset the command list

  Scenario: Register a public key file for a user
    When I run `conjur pubkeys add alice @id_alice.pub`
    Then the exit status should be 0

  Scenario: You can't accidentally register the private key
    When I run `conjur pubkeys add alice @id_alice`
    Then the exit status should be 1
    And the stderr should contain "Unprocessable Entity"

  Scenario: Unauthorized users cannot modify public keys
    Given I login as "bob"
    And I reset the command list
    And I run `conjur pubkeys add alice @id_alice.pub` 
    Then the exit status should be 1
    And the stderr should contain "Forbidden"
