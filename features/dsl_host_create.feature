@dsl
Feature: Creating a Host

  Background:

  Scenario: Host id is propagated properly to API#create_host
    When I run script:
    """
host "the-host"
    """
    Then the model should contain "host" "the-host"
