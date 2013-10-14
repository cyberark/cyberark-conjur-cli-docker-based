@dsl
Feature: Assigning ownership

  Background:

  Scenario: Create without ownership
    When I run script:
    """
role "user", "bob"
    """
    Then the "role" "cucumber:user:bob" should not have an owner

  Scenario: Create with explicit ownership
    When I run script:
    """
role "user", "bob", ownerid: "foobar"
    """
    Then the "role" "cucumber:user:bob" should be owned by "foobar"
    
  Scenario: Create with scoped ownership
    When I run script:
    """
role "user", "bob" do
  owns do
    resource "food", "bacon"
  end
end
    """
    Then the "resource" "cucumber:food:bacon" should be owned by "cucumber:user:bob"
    