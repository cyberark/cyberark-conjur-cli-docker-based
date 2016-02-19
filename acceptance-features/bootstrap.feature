Feature: "conjur bootstrap" creates default resources, privileges and roles

	Background:
    Given I successfully run `conjur bootstrap -q`

	Scenario: Run bootstrap and test for the existence of things
    Then I successfully run `conjur group show security_admin`
    And  I successfully run `conjur host show conjur/secrets-rotator`

	Scenario: A new security admin can use 'elevate'
    When I successfully run `conjur resource permitted_roles '!:!:conjur' elevate`
    Then the stdout should contain "cucumber:group:security_admin"
	