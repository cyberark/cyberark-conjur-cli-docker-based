Feature: Retire a policy
  Background:
    Given a file named "policy.rb" with:
    """
policy 'test-policy-1.0' do
end
    """
    And I run `conjur rubydsl load --as-role user:admin@$ns --collection $ns` interactively
    And I pipe in the file "policy.rb"
    And the exit status should be 0

  @wip
  Scenario: Basic retirement
    Then I successfully run `conjur rubydsl retire -d user:attic@$ns $ns/test-policy-1.0`

