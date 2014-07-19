require 'spec_helper'

tmpdir = Dir.mktmpdir

GITHUB_FP = "SHA1 Fingerprint=A0:C4:A7:46:00:ED:A7:2D:C0:BE:CB:9A:8C:B6:07:CA:58:EE:74:5E"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIF4DCCBMigAwIBAgIQDACTENIG2+M3VTWAEY3chzANBgkqhkiG9w0BAQsFADB1
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMTQwMgYDVQQDEytEaWdpQ2VydCBTSEEyIEV4dGVuZGVk
IFZhbGlkYXRpb24gU2VydmVyIENBMB4XDTE0MDQwODAwMDAwMFoXDTE2MDQxMjEy
MDAwMFowgfAxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9uMRMwEQYLKwYB
BAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQITCERlbGF3YXJlMRAwDgYDVQQF
Ewc1MTU3NTUwMRcwFQYDVQQJEw41NDggNHRoIFN0cmVldDEOMAwGA1UEERMFOTQx
MDcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T
YW4gRnJhbmNpc2NvMRUwEwYDVQQKEwxHaXRIdWIsIEluYy4xEzARBgNVBAMTCmdp
dGh1Yi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx1Nw8r/3z
Tu3BZ63myyLot+KrKPL33GJwCNEMr9YWaiGwNksXDTZjBK6/6iBRlWVm8r+5TaQM
Kev1FbHoNbNwEJTVG1m0Jg/Wg1dZneF8Cd3gE8pNb0Obzc+HOhWnhd1mg+2TDP4r
bTgceYiQz61YGC1R0cKj8keMbzgJubjvTJMLy4OUh+rgo7XZe5trD0P5yu6ADSin
dvEl9ME1PPZ0rd5qM4J73P1LdqfC7vJqv6kkpl/nLnwO28N0c/p+xtjPYOs2ViG2
wYq4JIJNeCS66R2hiqeHvmYlab++O3JuT+DkhSUIsZGJuNZ0ZXabLE9iH6H6Or6c
JL+fyrDFwGeNAgMBAAGjggHuMIIB6jAfBgNVHSMEGDAWgBQ901Cl1qCt7vNKYApl
0yHU+PjWDzAdBgNVHQ4EFgQUakOQfTuYFHJSlTqqKApD+FF+06YwJQYDVR0RBB4w
HIIKZ2l0aHViLmNvbYIOd3d3LmdpdGh1Yi5jb20wDgYDVR0PAQH/BAQDAgWgMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjB1BgNVHR8EbjBsMDSgMqAwhi5o
dHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1ldi1zZXJ2ZXItZzEuY3JsMDSg
MqAwhi5odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1ldi1zZXJ2ZXItZzEu
Y3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAIBMCowKAYIKwYBBQUHAgEWHGh0dHBz
Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYgGCCsGAQUFBwEBBHwwejAkBggrBgEF
BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFIGCCsGAQUFBzAChkZodHRw
Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyRXh0ZW5kZWRWYWxp
ZGF0aW9uU2VydmVyQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQAD
ggEBAG/nbcuC8++QhwnXDxUiLIz+06scipbbXRJd0XjAMbD/RciJ9wiYUhcfTEsg
ZGpt21DXEL5+q/4vgNipSlhBaYFyGQiDm5IQTmIte0ZwQ26jUxMf4pOmI1v3kj43
FHU7uUskQS6lPUgND5nqHkKXxv6V2qtHmssrA9YNQMEK93ga2rWDpK21mUkgLviT
PB5sPdE7IzprOCp+Ynpf3RcFddAkXb6NqJoQRPrStMrv19C1dqUmJRwIQdhkkqev
ff6IQDlhC8BIMKmCNK33cEYDfDWROtW7JNgBvBTwww8jO1gyug8SbGZ6bZ3k8OV8
XX4C2NesiZcLYbc2n7B9O+63M2k=
-----END CERTIFICATE-----
EOF

describe Conjur::Command::Init do
  it "properly defaults to a file path" do
    expect(Conjur::CLI.commands[:init].flags[:f].default_value).to eq("#{ENV['HOME']}/.conjurrc")
  end

  describe ".get_certificate" do
    it "returns the right certificate from github" do
      fingerprint, certificate = Conjur::Command::Init.get_certificate('github.com:443')
      expect(fingerprint).to eq(GITHUB_FP)
      expect(certificate.strip).to eq(GITHUB_CERT.strip)
    end
  end

  context logged_in: false do
    before {
      File.stub(:exists?).and_return false
    }
    context "auto-fetching fingerprint" do
      before {
        HighLine.any_instance.stub(:ask).with("Enter the hostname (and optional port) of your Conjur endpoint: ").and_return "the-host"
        Conjur::Command::Init.stub get_certificate: ["the-fingerprint", nil]
        HighLine.any_instance.stub(:ask).with(/^Trust this certificate/).and_return "yes"
      }
      describe_command 'init' do
        it "fetches account and writes config file" do
          # Stub hostname
          Conjur::Core::API.should_receive(:info).and_return "account" => "the-account"
          File.should_receive(:open)
          invoke
        end
      end
      describe_command 'init -a the-account' do
        it "writes config file" do
          File.should_receive(:open)
          invoke
        end
      end
    end
    describe_command 'init -a the-account -h foobar' do
      it "can't get the cert" do
        expect { invoke }.to raise_error(GLI::CustomExit, /unable to retrieve certificate/i)
      end
    end
    # KEG: These tests have a nasty habit of hanging
#    describe_command 'init -a the-account -h google.com' do
#      it "writes the config and cert" do
#        HighLine.any_instance.stub(:ask).and_return "yes"
#        File.should_receive(:open).twice
#        invoke
#      end
#    end
#    describe_command 'init -a the-account -h https://google.com' do
#      it "writes the config and cert" do
#        HighLine.any_instance.stub(:ask).and_return "yes"
#        File.should_receive(:open).twice
#        invoke
#      end
#    end
    describe_command 'init -a the-account -h localhost -c the-cert' do
      it "writes config and cert files" do
        File.should_receive(:open).twice
        invoke
      end
    end
    context "in a temp dir" do
      describe_command "init -f #{tmpdir}/.conjurrc -a the-account -h localhost -c the-cert" do
        it "writes config and cert files" do
          invoke
          
          expect(YAML.load(File.read(File.join(tmpdir, ".conjurrc")))).to eq({
            account: 'the-account',
            appliance_url: "https://localhost/api",
            cert_file: "#{tmpdir}/conjur-the-account.pem",
            plugins: [],
          }.stringify_keys)

          File.read(File.join(tmpdir, "conjur-the-account.pem")).should == "the-cert\n"
        end
      end
    end
  end
end
