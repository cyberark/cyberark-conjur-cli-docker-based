@dsl
Feature: Saving and restoring context

  Background:

  Scenario: Environment and api keys are saved in the context
    When I run script:
    """
namespace do
  user "bob"
end
    """
    Then the context should contain "env"
    And the context should contain "namespace"
    And the context should contain "stack"
    And the context should contain "account"
    And the context should contain "api_keys"
    And the context "api_keys" should contain "1" item

  Scenario: API keys are restored from the context
    When I use script context:
    """
{
  "namespace": "foobar",
  "api_keys": [
    "the-api-key"
  ]
}
    """
    And I run script:
    """
namespace
    """
    Then the context "namespace" should be "foobar"
    And the context "api_keys" should contain "1" item
    