@wip
Feature: Remove a public key

  Background:
    Given I successfully run `conjur user create alice@$ns`
    And I successfully run `ssh-keygen -t rsa -C "laptop" -N "" -f ./id_alice_$ns`

  Scenario: To remove a public key, use the user's login name and the key name (-C option to ssh-keygen)
    Given I successfully run `conjur pubkeys add alice@$ns @id_alice_$ns.pub`
    Then I successfully run `conjur pubkeys delete alice@$ns laptop`
