@dsl
Feature: Manpipulating permissions

  Background:

  Scenario: Permit using Role#can
    When I run script:
    """
bacon = resource "food", "bacon"
role "user", "bob" do
  can "fry", bacon
end
    """
    Then "cucumber:user:bob" can "fry" "cucumber:food:bacon"

  Scenario: Permit using Role#can with grant option
    When I run script:
    """
bacon = resource "food", "bacon"
role "user", "bob" do
  can "fry", bacon, grant_option: true
end
    """
    Then "cucumber:user:bob" can "fry" "cucumber:food:bacon" with grant option
    
  Scenario: Permit using Resource#permit
    When I run script:
    """
bob = role "user", "bob"
resource "food", "bacon" do
  permit "fry", bob
end
    """
    Then "cucumber:user:bob" can "fry" "cucumber:food:bacon"

  Scenario: Permit using Resource#permit with grant option
    When I run script:
    """
bob = role "user", "bob"
resource "food", "bacon" do
  permit "fry", bob, grant_option: true
end
    """
    Then "cucumber:user:bob" can "fry" "cucumber:food:bacon" with grant option
    