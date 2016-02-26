Feature: The CLI checks to ensure that the calling role is sufficiently privileged to create the host factory

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
