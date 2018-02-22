Feature: Authenticate a role

  Scenario: Get a JSON token
    When I successfully run `conjur authn authenticate`
    Then the JSON should have "protected"
    And the JSON should have "signature"
    And the JSON should have "payload"

  Scenario: Get an auth token as HTTP Authorize header
    When I successfully run `conjur authn authenticate -H`
    Then the output should match /Authorization: Token token=".*"/

#  Scenario: The API key of a new user is available and can be used to authenticate.
#    Given I load the policy:
#    """
#    - !user alice
#    """
#    And I login as "alice"
#    When I successfully run `conjur authn authenticate`
#    Then the JSON at "data" should be "alice"

  @announce-command
  @announce-output
  Scenario: The access token can be continuously refreshed in a file.
    When I run `env CONJUR_TOKEN_LIFESPAN=2 CONJUR_TOKEN_REFRESH_DELAY=1 CONJURAPI_LOG=stderr conjur authn authenticate -f /tmp/token` interactively
    And I run `sleep inf`
    Then the output should contain:
    """
    Authenticating admin to account cucumber
    Refreshed Conjur auth token to "/tmp/token"
    Authenticating admin to account cucumber
    Refreshed Conjur auth token to "/tmp/token"
    Authenticating admin to account cucumber
    Refreshed Conjur auth token to "/tmp/token"
    """
