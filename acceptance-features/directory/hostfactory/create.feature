Feature: Create a Host Factory

  Background:

  Scenario: Create a host factory successfully
    Given I successfully run `conjur layer create --as-group $ns/security_admin $ns/layer`
    Then I successfully run `conjur hostfactory create --as-group $ns/security_admin --layer $ns/layer $ns/hostfactory`

	Scenario: The client role can use itself as the hostfactory role
    Given I successfully run `conjur user create unprivileged@$ns`
    And I successfully run `conjur layer create $ns/layer`
    When I run `conjur hostfactory create --as-role user:unprivileged@$ns --layer $ns/layer $ns/hostfactory`

	Scenario: If current role cannot admin the layer, the error is reported
		Given I successfully run `conjur layer create $ns/the-layer`
		And I login as a new user
		Given I successfully run `conjur group create $ns/the-group`
		And I run `conjur hostfactory create --as-group $ns/the-group -l $ns/the-layer $ns/the-factory`
		Then the exit status should not be 0
		And the output should contain "must be an admin of layer"
	
	Scenario: If current role cannot admin the HF role, the error is reported
		Given I successfully run `conjur group create $ns/the-group`
		And I login as a new user
		Given I successfully run `conjur layer create $ns/the-layer`
		And I run `conjur hostfactory create --as-group $ns/the-group -l $ns/the-layer $ns/the-factory`
		Then the exit status should not be 0
		And the output should contain "must be an admin of role"
