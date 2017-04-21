require 'spec_helper'
require 'highline'

GITHUB_FP = "SHA1 Fingerprint=D7:9F:07:61:10:B3:92:93:E3:49:AC:89:84:5B:03:80:C1:9E:2F:8B"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIEtjCCA56gAwIBAgIQDHmpRLCMEZUgkmFf4msdgzANBgkqhkiG9w0BAQsFADBs
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j
ZSBFViBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowdTEL
MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
LmRpZ2ljZXJ0LmNvbTE0MDIGA1UEAxMrRGlnaUNlcnQgU0hBMiBFeHRlbmRlZCBW
YWxpZGF0aW9uIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBANdTpARR+JmmFkhLZyeqk0nQOe0MsLAAh/FnKIaFjI5j2ryxQDji0/XspQUY
uD0+xZkXMuwYjPrxDKZkIYXLBxA0sFKIKx9om9KxjxKws9LniB8f7zh3VFNfgHk/
LhqqqB5LKw2rt2O5Nbd9FLxZS99RStKh4gzikIKHaq7q12TWmFXo/a8aUGxUvBHy
/Urynbt/DvTVvo4WiRJV2MBxNO723C3sxIclho3YIeSwTQyJ3DkmF93215SF2AQh
cJ1vb/9cuhnhRctWVyh+HA1BV6q3uCe7seT6Ku8hI3UarS2bhjWMnHe1c63YlC3k
8wyd7sFOYn4XwHGeLN7x+RAoGTMCAwEAAaOCAUkwggFFMBIGA1UdEwEB/wQIMAYB
Af8CAQAwDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEF
BQcDAjA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
Z2ljZXJ0LmNvbTBLBgNVHR8ERDBCMECgPqA8hjpodHRwOi8vY3JsNC5kaWdpY2Vy
dC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMD0GA1UdIAQ2
MDQwMgYEVR0gADAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5j
b20vQ1BTMB0GA1UdDgQWBBQ901Cl1qCt7vNKYApl0yHU+PjWDzAfBgNVHSMEGDAW
gBSxPsNpA/i/RwHUmCYaCALvY2QrwzANBgkqhkiG9w0BAQsFAAOCAQEAnbbQkIbh
hgLtxaDwNBx0wY12zIYKqPBKikLWP8ipTa18CK3mtlC4ohpNiAexKSHc59rGPCHg
4xFJcKx6HQGkyhE6V6t9VypAdP3THYUYUN9XR3WhfVUgLkc3UHKMf4Ib0mKPLQNa
2sPIoc4sUqIAY+tzunHISScjl2SFnjgOrWNoPLpSgVh5oywM395t6zHyuqB8bPEs
1OG9d4Q3A84ytciagRpKkk47RpqF/oOi+Z6Mo8wNXrM9zwR4jxQUezKcxwCmXMS1
oVWNWlZopCJwqjyBcdmdqEU79OX2olHdx3ti6G8MdOu42vi/hw15UJGQmxg7kVkn
8TUoE6smftX3eg==
-----END CERTIFICATE-----
EOF

describe Conjur::Command::Init do
  describe ".get_certificate" do
    it "returns the right certificate from github" do
      fingerprint, certificate = Conjur::Command::Init.get_certificate('github.com:443')
      expect(fingerprint).to eq(GITHUB_FP)
      expect(certificate.strip).to include(GITHUB_CERT.strip)
    end
  end

  context logged_in: false do
    before {
      allow(File).to receive(:exists?).and_return false
    }

    context "auto-fetching fingerprint" do
      before {
        allow_any_instance_of(HighLine).to receive(:ask).with("Enter the hostname (and optional port) of your Conjur endpoint: ").and_return "the-host"
        allow(Conjur::Command::Init).to receive_messages get_certificate: ["the-fingerprint", nil]
        allow_any_instance_of(HighLine).to receive(:ask).with(/^Trust this certificate/).and_return "yes"
      }

      describe_command 'init' do
        it "fetches account and writes config file" do
          # Stub hostname
          expect(Conjur::Core::API).to receive(:info).and_return "account" => "the-account"
          expect(File).to receive(:open)
          invoke
        end
      end

      describe_command 'init -a the-account' do
        it "writes config file" do
          expect(File).to receive(:open)
          invoke
        end
      end
    end

    describe_command 'init -a the-account -u https://foobar' do
      it "can't get the cert" do
        expect { invoke }.to raise_error(GLI::CustomExit, /unable to retrieve certificate/i)
      end
    end

    describe_command 'init -a the-account -u https://localhost -c the-cert' do
      it "writes config and cert files" do
        expect(File).to receive(:open).twice
        expect(Conjur::Command::Init).to receive(:configure_cert_store).with "the-cert"
        invoke
      end
    end

    context "in a temp dir" do
      tmpdir = Dir.mktmpdir

      shared_examples "check config and cert files" do |file, env|
        around do |example|
          Dir.foreach(tmpdir) {|f|
            fn = File.join(tmpdir, f)
            File.delete(fn) if f != '.' && f != '..'
          }
          f = ENV.delete 'CONJURRC'
          if not env.nil?
            ENV['CONJURRC'] = env
          end
          example.run
          ENV['CONJURRC'] = f
        end

        it "writes config and cert files" do
          invoke

          expect(YAML.load(File.read(file))).to eq({
            account: 'the-account',
            appliance_url: "https://localhost/api",
            cert_file: File.join(File.dirname(file), "conjur-the-account.pem"),
            plugins: [],
          }.stringify_keys)
        end
      end
      
      context "default behavior" do
        describe_command "init -a the-account -u https://localhost -c the-cert" do
          before(:each) {
            allow(File).to receive(:expand_path).and_call_original
            allow(File).to receive(:expand_path).with('~/.conjurrc').and_return("#{tmpdir}/.conjurrc")
          }
  
          include_examples "check config and cert files", "#{tmpdir}/.conjurrc"
          it "prints the config file location" do
            expect { invoke }.to write("Wrote configuration to #{tmpdir}/.conjurrc")
          end
          it "prints the cert location" do
            expect { invoke }.to write("Wrote certificate to #{tmpdir}/conjur-the-account.pem")
          end
        end
      end

      context "explicit output file" do
        describe_command "init -f #{tmpdir}/.conjurrc2 -a the-account -u https://localhost -c the-cert" do
          include_examples "check config and cert files", File.join(tmpdir, ".conjurrc2")
          it "prints the config file location" do
            expect { invoke }.to write("Wrote configuration to #{tmpdir}/.conjurrc2")
          end
        end
      end

      context "to CONJURRC" do
        describe_command "init -a the-account -u https://localhost -c the-cert" do
          file = File.join(tmpdir, ".conjurrc_env")
          include_examples "check config and cert files", file, file
        end
      end
      
      context "explicit output file overrides CONJURRC" do
        describe_command "init -f #{tmpdir}/.conjurrc_2 -a the-account -u https://localhost -c the-cert" do
          ENV['CONJURRC'] = "#{tmpdir}/.conjurrc_env_2"
          include_examples "check config and cert files", File.join(tmpdir, ".conjurrc_2")
        end
      end
    end
  end
end
