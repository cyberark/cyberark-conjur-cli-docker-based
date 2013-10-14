@dsl
Feature: Creating a User

  Background:

  Scenario: Users don't incorporate the namespace as a path prefix
    When I run script:
    """
namespace do
  user "bob"
end
    """
    Then the model should contain "user" "bob"

  Scenario: Namespace can be used as a no-arg method
    When I run script:
    """
namespace "foobar" do
  user "#{namespace}-bob"
end
    """
    Then the model should contain "user" "foobar-bob"
    