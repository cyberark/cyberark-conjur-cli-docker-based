Feature: Show public keys for a user

  Background:
    Given I successfully run `conjur user create alice@$ns`
    And I successfully run `ssh-keygen -t rsa -C "laptop" -N "" -f ./id_alice_$ns`

  Scenario: Initial key list is empty
    When I run `conjur pubkeys show alice@$ns`
    Then the stdout from "conjur pubkeys show alice@$ns" should contain exactly "\n"

  Scenario: After adding a key, the key is shown
    Given I successfully run `conjur pubkeys add alice@$ns @id_alice_$ns.pub`
    And I run `conjur pubkeys show alice@$ns`
    And the output should match /^ssh-rsa .* laptop$/

  Scenario: After deleting the key, the key list is empty again
    Given I successfully run `conjur pubkeys add alice@$ns @id_alice_$ns.pub`
    And I successfully run `conjur pubkeys delete alice@$ns laptop`
    And I run `conjur pubkeys show alice@$ns`
    Then the stdout from "conjur pubkeys show alice@$ns" should contain exactly "\n"

  Scenario: Public keys can be listed using cURL, without authentication
    Given I successfully run `conjur pubkeys add alice@$ns @id_alice_$ns.pub`
    When I successfully run `curl -k $pubkeys_url/alice@$ns`
    Then the output should match /^ssh-rsa .* laptop$/
