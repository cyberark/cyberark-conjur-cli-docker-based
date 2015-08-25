Feature: Register a public key

  Background:
    Given I successfully run `conjur user create alice@$ns`
    And I successfully run `ssh-keygen -t rsa -C "laptop" -N "" -f ./id_alice_$ns`

  Scenario: Register a public key file for a user
    When I run `conjur pubkeys add alice@$ns @id_alice_$ns.pub`
    Then the exit status should be 0

  Scenario: You can't accidentally register the private key
    When I run `conjur pubkeys add alice@$ns @id_alice_$ns`
    Then the exit status should be 1
    And the stderr from "conjur pubkeys add alice@$ns @id_alice_$ns" should contain "Unprocessable Entity"

  Scenario: Unauthorized users cannot modify public keys
    Given I login as new user "bob@$ns"
    And I run `conjur pubkeys add alice@$ns @id_alice_$ns.pub` 
    Then the exit status should be 1
    And the stderr from "conjur pubkeys add alice@$ns @id_alice_$ns.pub" should contain "Forbidden"
