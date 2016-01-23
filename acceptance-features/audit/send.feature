Feature: Create custom audit events

    Background:
        Given I login as new user "joe@$ns"

    Scenario: Simplest audit event
        When I successfully run `conjur audit send '{"action":"login"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login/
    
    Scenario: Expose facility
        When I successfully run `conjur audit send '{"action":"login", "facility":"ssh"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported ssh:login/

    Scenario: Link to role
        When I successfully run `conjur audit send '{"action":"login", "role":"user:bob"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login by .*:user:bob/
        
    Scenario: Link to resource
        When I successfully run `conjur audit send '{"action":"login", "resource_id":"host:server"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login on .*:host:server/


    Scenario: 'Allowed' flag
        When I successfully run `conjur audit send '{"action":"login", "allowed": false}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login \(allowed: false\)/

    Scenario: Custom message
        When I successfully run `conjur audit send '{"action":"login", "audit_message": "Client IP is 1.2.3.4"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login; message: Client IP is 1.2.3.4/
    
    Scenario: Error details
        When I successfully run `conjur audit send '{"action":"login", "error": "password mismatch"}'`
        And I run `conjur audit all -s`
        Then the output should match /user:joe@.* reported login \(failed with password mismatch\)/

    Scenario: Specify timestamp as IS08601 with timezone
        When I successfully run `conjur audit send '{"action":"login", "timestamp": "2014-07-01T01:02:03Z"}'`
        And I run `conjur audit all -s`
        Then the output should match /\[2014-07-01 01:02:03 UTC\] .*:user:joe@.* reported login/

    Scenario: Arbitrary field (exposed in full audit output)
        When I successfully run `conjur audit send '{"action":"login", "syslog": { "message" : "Accepted publickey for alice from 192.168.1.11 port 38977 ssh2" }}'`
        And I run `conjur audit all -o 3` 
        Then the JSON response at "syslog/message" should be "Accepted publickey for alice from 192.168.1.11 port 38977 ssh2"
        
