@wip
Feature: Write and read custom audit events (full-stack test, not for publication)

    Background: 
        Given I create a new user named "eve@$ns"
        And I create a new host with id "monitoring/server"
        And I create a new user named "observer@$ns"
        And I run `conjur resource permit host:$ns/monitoring/server user:observer@$ns read`
        And I run `conjur role grant_to user:eve@$ns user:observer@$ns`
        And I run `conjur role grant_to host:$ns/monitoring/server user:observer@$ns`
        And I login as the new host
        And I send the audit event:
        """
        {
          "facility": "custom",
          "action": "sudo",
          "system_user": "eve",
          "allowed": false,
          "role": "user:eve@$ns",
          "resource_id": "host:$ns/monitoring/server",
          "error": "user NOT in sudoers",
          "audit_message": "eve tried to run '/bin/cat /etc/shadow' as root",   
          "command": "/bin/cat /etc/shadow",
          "target_user": "root",
          "sudo": {
            "TTY": "pts/0",
            "PWD": "/home/eve",
            "USER": "root",
            "COMMAND": "/bin/cat /etc/shadow"
          },
          "timestamp": "2014-06-30T03:25:00.542768+00:00"
        }
        """   
        And I login as "observer@$ns"
        And I reset the command list

    Scenario: Custom event is indexed by explictly submitted resources
        When I run `conjur audit resource -s host:$ns/monitoring/server`
        Then the stdout should contain "reported custom:sudo by cucumber:user:eve"
        And  the stdout should contain "allowed: false"
        And  the stdout should contain "eve tried to run"

    Scenario: Custom event is indexed by the role which submitted it
        When I run `conjur audit role -s host:$ns/monitoring/server`
        Then the stdout should contain "reported custom:sudo by cucumber:user:eve"
        And  the stdout should contain "allowed: false"
        And  the stdout should contain "eve tried to run"

    Scenario: Custom event is indexed by explicitly submitted roles
        When I run `conjur audit role -s user:eve@$ns`
        Then the stdout should contain "reported custom:sudo by cucumber:user:eve"
        And  the stdout should contain "allowed: false"
        And  the stdout should contain "eve tried to run"

    Scenario: Default fields are included in audit event
        When I run `conjur audit resource -l 1 -o 3 host:$ns/monitoring/server`
        Then the JSON response should have the following:
            | id                    |
            | event_id              |
            | timestamp             |
            | submission_timestamp  |
            | kind                  |
            | action                |
            | user                  |
            | acting_as             |
            | roles                 |
            | resources             |
            | resource              |
            | request               |
            | conjur                |

    Scenario: Default fields are filled properly
        When I run `conjur audit resource -l 1 -o 3 host:$ns/monitoring/server`
        Then the JSON response at "timestamp" should include "2014-06-30T03:25:00"
        And the JSON response at "kind" should be "audit"
        And the JSON response at "action" should be "sudo"
        And the JSON response at "user" should include "/monitoring/server"
        And the JSON response at "roles/0" should include "/monitoring/server"
        And the JSON response at "roles/1" should include "user:eve@"
        And the JSON response at "resource" should include "/monitoring/server"
        And the JSON response at "resources/0" should include "/monitoring/server"
        And the JSON response at "conjur/user" should include "/monitoring/server"
        
    Scenario: All custom fields are exposed
        When I run `conjur audit resource -l 1 -o 3 host:$ns/monitoring/server`
        Then the JSON response should have the following:
            | facility              |
            | system_user           |   
            | allowed               |
            | role                  |
            | resource_id           |
            | error                 |
            | audit_message         |
            | command               |
            | target_user           |
            | sudo                  |
    
    Scenario: Custom fields are filled properly
        When I run `conjur audit resource -l 1 -o 3 host:$ns/monitoring/server`
        And the JSON response at "facility" should be "custom"
        And the JSON response at "system_user" should include "eve"
        And the JSON response at "allowed" should be false
        And the JSON response at "role" should include "user:eve@"
        And the JSON response at "resource_id" should include "/monitoring/server"
        And the JSON response at "error" should be "user NOT in sudoers"
        And the JSON response at "command" should be "/bin/cat /etc/shadow"
        And the JSON response at "target_user" should be "root"
        And the JSON response at "sudo/PWD" should be "/home/eve"
