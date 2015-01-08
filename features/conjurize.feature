Feature: conjurize program generates install scripts

  Scenario: App just runs
    When I get help for "conjurize"
    Then the exit status should be 0
    And the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
    And the banner should document that this app takes no arguments

  Scenario: Minimal conjurize script
    When I conjurize ""
    Then the stdout should contain exactly:
"""
#!/bin/sh
set -e

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.

tee /etc/conjur.conf > /dev/null << CONJUR_CONF
account: test
appliance_url: https://conjur/api
cert_file: /etc/conjur-test.pem
netrc_path: /etc/conjur.identity
plugins: []
CONJUR_CONF

tee /etc/conjur-test.pem > /dev/null << CONJUR_CERT
-----BEGIN CERTIFICATE-----
MIIDZTCCAk2gAwIBAgIJAMzfPBZBq82XMA0GCSqGSIb3DQEBBQUAMDMxMTAvBgNV
BAMTKGVjMi01NC04My05OS0xMzUuY29tcHV0ZS0xLmFtYXpvbmF3cy5jb20wHhcN
MTQxMTIxMTUxNDE0WhcNMjQxMTE4MTUxNDE0WjAzMTEwLwYDVQQDEyhlYzItNTQt
ODMtOTktMTM1LmNvbXB1dGUtMS5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAlkhRt1pvOkw1JTtvmfa3lHpT00g0lbBnShN5cKI3
cT1Na3aGdosPDfn0z+A6GNT2sUcdsc5RLkrZKG2+57B5hyUtdwRoJoTTBqypxJTc
vkeMpCrcaeY8Ye0zsoBNaeauXLPobtEV4I6IadJGuT2AKILTJLDYdyV4dg2/zN2z
XmW+9FsDs+aJKtWnpBIkvXcCqbaIgRZSxFNeZUF+xDrZdCRm+qkBXZaMFQzLU0BT
B239Lmpwp54zsBoTBY9JBS4Atmrwt3YE3JqcIH77GpkgXSx203bYVp0jF3vPxHLU
bSqhV9Zw7m6V8uF+jvOdrDiZ33OJN9yx6nS+c7NfOyRgGQIDAQABo3wwejB4BgNV
HREEcTBvgglsb2NhbGhvc3SCBmNvbmp1coIVY29uanVyLWRldi5jb25qdXIubmV0
ghljb25qdXItZGV2Lml0ZC5jb25qdXIubmV0gihlYzItNTQtODMtOTktMTM1LmNv
bXB1dGUtMS5hbWF6b25hd3MuY29tMA0GCSqGSIb3DQEBBQUAA4IBAQB+alzAA3ek
o8QrnoDuWOxTqD0XIwzqux6BM/nM4dZX6drr+D0y8QtMKLZNODazvFCJWNHAWWmD
FkRudwl3G1Qs56AB+LnQ2jhL5Qf78Rl2vYvdmo8iowEpOBajvzEMLsEaRNmwmSGc
yvml0YdVSiMdTdIk58qG84pkmteSX9VYE1IF7xfWb3ji8292fm5q6cgqFLNYx2MI
5UyfyroGMJ2ikzTGS64TpCmi/n1sjl2iM+/QmkHVc3KUIdwAY2NttyZ2pZo2J4i6
MVs0y+HobWbOKKhyfxpMT59dJxGu21QPbWfQLkHCCOlo2P4z9oku23sbvQQ7CbvS
VoykXurdaZo9
-----END CERTIFICATE-----
CONJUR_CERT

tee /etc/conjur.identity > /dev/null << CONJUR_IDENTITY
machine https://conjur/api/authn
  login host/ec2/i-eaa5f700
  password 3a4rb19rpjejr89h6r29kd2fb3808cpy
CONJUR_IDENTITY
chmod 0600 /etc/conjur.identity

"""

  Scenario: conjurize with SSH installation
    When I conjurize "--ssh"
    Then the stdout should contain:
"""
#!/bin/sh
set -e

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.

tee /etc/conjur.conf > /dev/null << CONJUR_CONF
account: test
appliance_url: https://conjur/api
cert_file: /etc/conjur-test.pem
netrc_path: /etc/conjur.identity
plugins: []
CONJUR_CONF

tee /etc/conjur-test.pem > /dev/null << CONJUR_CERT
-----BEGIN CERTIFICATE-----
MIIDZTCCAk2gAwIBAgIJAMzfPBZBq82XMA0GCSqGSIb3DQEBBQUAMDMxMTAvBgNV
BAMTKGVjMi01NC04My05OS0xMzUuY29tcHV0ZS0xLmFtYXpvbmF3cy5jb20wHhcN
MTQxMTIxMTUxNDE0WhcNMjQxMTE4MTUxNDE0WjAzMTEwLwYDVQQDEyhlYzItNTQt
ODMtOTktMTM1LmNvbXB1dGUtMS5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAlkhRt1pvOkw1JTtvmfa3lHpT00g0lbBnShN5cKI3
cT1Na3aGdosPDfn0z+A6GNT2sUcdsc5RLkrZKG2+57B5hyUtdwRoJoTTBqypxJTc
vkeMpCrcaeY8Ye0zsoBNaeauXLPobtEV4I6IadJGuT2AKILTJLDYdyV4dg2/zN2z
XmW+9FsDs+aJKtWnpBIkvXcCqbaIgRZSxFNeZUF+xDrZdCRm+qkBXZaMFQzLU0BT
B239Lmpwp54zsBoTBY9JBS4Atmrwt3YE3JqcIH77GpkgXSx203bYVp0jF3vPxHLU
bSqhV9Zw7m6V8uF+jvOdrDiZ33OJN9yx6nS+c7NfOyRgGQIDAQABo3wwejB4BgNV
HREEcTBvgglsb2NhbGhvc3SCBmNvbmp1coIVY29uanVyLWRldi5jb25qdXIubmV0
ghljb25qdXItZGV2Lml0ZC5jb25qdXIubmV0gihlYzItNTQtODMtOTktMTM1LmNv
bXB1dGUtMS5hbWF6b25hd3MuY29tMA0GCSqGSIb3DQEBBQUAA4IBAQB+alzAA3ek
o8QrnoDuWOxTqD0XIwzqux6BM/nM4dZX6drr+D0y8QtMKLZNODazvFCJWNHAWWmD
FkRudwl3G1Qs56AB+LnQ2jhL5Qf78Rl2vYvdmo8iowEpOBajvzEMLsEaRNmwmSGc
yvml0YdVSiMdTdIk58qG84pkmteSX9VYE1IF7xfWb3ji8292fm5q6cgqFLNYx2MI
5UyfyroGMJ2ikzTGS64TpCmi/n1sjl2iM+/QmkHVc3KUIdwAY2NttyZ2pZo2J4i6
MVs0y+HobWbOKKhyfxpMT59dJxGu21QPbWfQLkHCCOlo2P4z9oku23sbvQQ7CbvS
VoykXurdaZo9
-----END CERTIFICATE-----
CONJUR_CERT

tee /etc/conjur.identity > /dev/null << CONJUR_IDENTITY
machine https://conjur/api/authn
  login host/ec2/i-eaa5f700
  password 3a4rb19rpjejr89h6r29kd2fb3808cpy
CONJUR_IDENTITY
chmod 0600 /etc/conjur.identity

curl -L https://www.opscode.com/chef/install.sh | bash

"""
    And the output should match:
    """
    chef-solo -r https:\/\/github.com\/conjur-cookbooks\/conjur-ssh\/releases\/download/v\d\.\d\.\d/conjur-ssh-v\d\.\d\.\d.tar.gz -o conjur-ssh
    """

  Scenario: conjurize with arbitrary cookbook
    When I conjurize "--conjur-cookbook-url https://example.com --conjur-run-list fry"
    Then the stdout should contain "chef-solo -r https://example.com -o fry"

  Scenario: conjurize with path to chef-solo
    When I conjurize "--chef-executable /path/to/chef-solo --conjur-cookbook-url https://example.com --conjur-run-list fry"
    Then the stdout should contain "/path/to/chef-solo -r https://example.com -o fry"
    And the stdout should not contain "curl -L https://www.opscode.com/chef/install.sh"

  Scenario: conjurize with sudo-ized commands
    When I conjurize "--sudo --ssh"
    Then the stdout should contain "sudo -n tee /etc/conjur.conf > /dev/null << CONJUR_CONF"
    And the stdout should contain "sudo -n tee /etc/conjur-test.pem > /dev/null << CONJUR_CERT"
    And the stdout should contain "sudo -n tee /etc/conjur.identity > /dev/null << CONJUR_IDENTITY"
    And the stdout should contain "sudo -n chmod 0600 /etc/conjur.identity"
    And the stdout should contain "curl -L https://www.opscode.com/chef/install.sh | sudo -n bash"

