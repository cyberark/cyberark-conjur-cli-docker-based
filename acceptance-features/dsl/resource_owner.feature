Feature: Resources created by a policy are owned by the policy

  Background:
    Given a file named "policy.rb" with:
    """
policy 'test-policy-1.0' do
  resource 'webservice', 'web1'
end
    """

  Scenario: resource is create with correct ownership
    When I run `conjur policy load --collection $ns` interactively
    And I pipe in the file "policy.rb"
    And the command completes successfully
    And I reset the command list
    When I run `conjur resource show webservice:$ns/test-policy-1.0/web1`
    Then the JSON at "owner" should be "cucumber:policy:%{NAMESPACE}/test-policy-1.0"
