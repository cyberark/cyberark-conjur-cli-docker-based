@real-api
Feature: Retrieving role graphs
  As a Conjur user
  In order to understand the role hierarchy
  I want to retrieve role graphs and present them in a useful format

Background:
  Given a graph with edges
    | Tywin     | Jamie         |
    | Tywin     | Cersei        |
    | Cersei    | Joffrey       |
    | Jamie     | Joffrey       |
    | Aerys     | Tyrion        |
    | Joanna    | Tyrion        |

  Scenario: Showing the graph as JSON
    When I successfully run "conjur role graph --as-role Joffrey Joffrey"
    Then the JSON should be:
      """
        {
          "graph": {
            { "parent": "Tywin",  "child": "Jamie" },
            { "parent": "Tywin",  "child": "Cersei"},
            { "parent": "Cersei", "child": "Joffrey"},
            { "parent": "Jamie",  "child": "Joffrey" }
          }
        }
      """

  Scenario: Short JSON output
    When I successfully run "conjur role graph --short --as-role Joffrey Joffrey"
    Then the JSON should be:
      """
        [
          [ "Tywin", "Jamie"   ],
          [ "Tywin", "Cersei"  ],
          [ "Jamie", "Joffrey" ],
          [ "Cersei", "Joffrey"]
        ]
      """

  Scenario: I can restrict the output to show only ancestors or descendants
    When I successfully run "conjur role graph --short --no-ancestors Cersei Cersei"
    Then the JSON should be:
      """
        [
          [ "Cersei", "Joffrey" ]
        ]
      """
    When I successfully run "conjur role graph --short --no-descendants Cersei Cersei Jamie"
    Then the JSON should be:
      """
        [
          [ "Tywin", "Cersei" ],
          [ "Tywin", "Jamie"  ]
        ]
      """

