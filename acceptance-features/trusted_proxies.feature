Feature: Conjur services support trusted proxies

  As an administrator of the Conjur Appliance, I want to be able to
  specify CIDRs for machines that should be regarded as trusted
  proxies. IP addresses that match those CIDRs can be regarded as
  coming from localhost. Other addresses should not be remapped (even
  if those addresses are non-routable), and so will appear in audit
  events and be used to validate CIDR restrictions (e.g. on
  hostfactory tokens).

  Scenario: authn supports trusted proxies for CIDR restrictions
    Given I set the JSON request body to:
    """
    {
      "login": "restricted@$ns",
      "password": "restricted",
      "ownerid": "cucumber:user:admin@$ns",
      "cidr": ["192.168.0.0/24"]
    }
    """
    And I send a POST request to "/api/users"
    And the response status should be "201"
    Given I send "text/plain" and accept JSON
    And I set the request body to "restricted"
    When I send a POST request from "192.168.0.1" to "/api/authn/users/restricted@$ns/authenticate"
    Then the response status should be "200"

  Scenario: authz supports trusted proxies
    Given I send a PUT request from "192.168.0.1" to "/api/authz/cucumber/resources/test/$ns/resource?acting_as=$user_role" 
    And the response status should be "204"
    When I successfully run `conjur audit resource test:$ns/resource`
    Then the JSON response at "request/ip" should be "192.168.0.1"

  Scenario: core supports trusted proxies
    Given I set the JSON request body to:
    """
    {
      "id": "$ns/var",
      "kind": "password",
      "mime_type": "text/plain"
    }    
    """
    And I send a POST request from "192.168.0.1" to "/api/variables"
    And the response status should be "201"
    When I successfully run `conjur audit resource variable:$ns/var`
    Then the JSON response at "request/ip" should be "192.168.0.1"

  Scenario: expiration supports trusted proxies
    Given I successfully run `conjur variable create $ns_expiration_var value`
    And I send a GET request from "192.168.0.1" to "/api/variables/$ns_expiration_var/value"
    And the response status should be "200"
    When I get the audit event for the resource "cucumber:variable:$ns_expiration_var" with action "check"
    Then the audit event should show the request from "192.168.0.1"

  Scenario: host-factory supports trusted proxies when creating hostfactories
    Given I successfully run `conjur layer create --as-role $user_role $ns/layer`
    When I send a POST request from "192.168.0.1" to "/api/host_factories" with: 
      | id     | roleid    | ownerid    | layers[]  |
      | $ns/hf | $user_role | $user_role | $ns/layer |

    And the response status should be "201"
    And I successfully run `conjur audit resource host_factory:$ns/hf`
    Then the JSON response at "request/ip" should be "192.168.0.1"

  Scenario: hostfactory supports trusted proxies when creating hosts
    Given I successfully run `conjur layer create --as-role $user_role $ns/layer`
    And I successfully run `conjur hostfactory create --as-role $user_role --layer $ns/layer $ns/hf`
    And I create a hostfactory token for "$ns/hf" with CIDR "192.168.0.0/16"
    When I use the hostfactory token from "192.168.0.1" to create host "$ns/host"
    And I get the audit event for the resource "cucumber:host:$ns/host" with action "create"
    Then the audit event should show the request from "192.168.0.1"

  Scenario: hostfactory supports trusted proxies when validating token CIDR restrictions
    Given I successfully run `conjur layer create --as-role $user_role $ns/layer`
    And I successfully run `conjur hostfactory create --as-role $user_role --layer $ns/layer $ns/hf`
    And I create a hostfactory token for "$ns/hf" with CIDR "192.168.0.0/16"
    Then I can use the hostfactory token from "192.168.0.1" to create host "$ns/host1"

  Scenario: pubkeys supports trusted proxies
    Given I create a pubkey for "pubkeys_user@$ns" from "192.168.0.1" with "ssh-rsa foobar pubkeys_user@host"
    When I get the audit event for the pubkey variable with action "create"
    Then the audit event should show the request from "192.168.0.1"
