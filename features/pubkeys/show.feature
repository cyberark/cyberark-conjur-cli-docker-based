Feature: Show public keys for a user

  Background:
    Given I load the policy:
    """
    - !user
      id: alice
      public_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQ laptop
    """

  Scenario: After adding a key, the key is shown
    When I run `conjur pubkeys show alice`
    And the output should match /^ssh-rsa .* laptop$/
