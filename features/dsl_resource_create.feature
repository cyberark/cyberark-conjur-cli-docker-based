@dsl
Feature: Creating a resource

  Background:

  Scenario: Create with simple kind and id
    When I run script:
    """
resource "food", "bacon"
    """
    Then the model should contain "resource" "cucumber:food:bacon"

  Scenario: Create with scope
    When I run script:
    """
scope "test" do
  resource "food", "bacon"
end
resource "food", "eggs"
    """
    Then the model should contain "resource" "cucumber:food:test/bacon"
    And the model should contain "resource" "cucumber:food:eggs"
    