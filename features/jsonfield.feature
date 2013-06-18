Feature: Extracting JSON fields

  In order to use conjur output in shell scripts
  As a Conjur user
  I want to extract fields from JSON data

  Scenario: An array element
    When I successfully run `jsonfield 2 '[1, 2, 3]'`
    Then the output should contain "3"

  Scenario: An out of bounds array element
    When I run `jsonfield 3 '[1, 2, 3]'`
    Then the output should contain "No field 3"
    And the exit status should be 2

  Scenario: A hash element
    When I successfully run `jsonfield a '{"a": 4}'`
    Then the output should contain "4"

  Scenario: A non-existent hash element
    When I run `jsonfield b '{"a": 4}'`
    Then the output should contain "No field b"
    And the exit status should be 2

  Scenario: Nested elements
    When I successfully run `jsonfield 0.a.1.b '[{"a": [42, {"b": "foo", "d": null}, 33], "bar": true}]'`
    Then the output should contain "foo"

  Scenario: Standard input
    Given a file named "test.json" with:
      """
        {
          "a": [
            42,
            {
              "b": "foo",
              "d": null
            },
            33
          ],
          "bar": true
        }
      """
    When I run `cat test.json | jsonfield 0.a.1.b`
    Then the output should contain "foo"

  Scenario: An element with hyphen in key
    When I successfully run `jsonfield variables.db-password '{"variables": {"db-password": "foo"}}'`
    Then the output should contain "foo"
