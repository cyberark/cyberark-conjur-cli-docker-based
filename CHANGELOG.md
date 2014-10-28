# 4.17.0

* Support --policy parameter in 'conjur env'
* Bugfix: failures on 'variable retire'
* Raise a better error in case of missing config

# 4.16.0

* Add 'bootstrap' CLI command
* Raise a better error if conjur env encounters a variable with no value 

# 4.15.0

* Migration to rspec 3
* Commands to retire(decommission) variable, host, user, group
* Bugfix (in some situations `conjur init` logged config file location incorrectly)
