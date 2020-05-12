require 'spec_helper'
require 'highline'

GITHUB_FP = "SHA1 Fingerprint=5F:3F:7A:C2:56:9F:50:A4:66:76:47:C6:A1:8C:A0:07:AA:ED:BB:8E"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIG1TCCBb2gAwIBAgIQBVfICygmg6F7ChFEkylreTANBgkqhkiG9w0BAQsFADBw
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMS8wLQYDVQQDEyZEaWdpQ2VydCBTSEEyIEhpZ2ggQXNz
dXJhbmNlIFNlcnZlciBDQTAeFw0yMDA1MDUwMDAwMDBaFw0yMjA1MTAxMjAwMDBa
MGYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T
YW4gRnJhbmNpc2NvMRUwEwYDVQQKEwxHaXRIdWIsIEluYy4xEzARBgNVBAMTCmdp
dGh1Yi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7MrTQ2J6a
nox5KUwrqO9cQ9STO5R4/zBUxxvI5S8bmc0QjWfIVAwHWuT0Bn/H1oS0LM0tTkQm
ARrqN77v9McVB8MWTGsmGQnS/1kQRFuKiYGUHf7iX5pfijbYsOkfb4AiVKysKUNV
UtgVvpJoe5RWURjQp9XDWkeo2DzGHXLcBDadrM8VLC6H1/D9SXdVruxKqduLKR41
Z/6dlSDdeY1gCnhz3Ch1pYbfMfsTCTamw+AtRtwlK3b2rfTHffhowjuzM15UKt+b
rr/cEBlAjQTva8rutYU9K9ONgl+pG2u7Bv516DwmNy8xz9wOjTeOpeh0M9N/ewq8
cgbR87LFaxi1AgMBAAGjggNzMIIDbzAfBgNVHSMEGDAWgBRRaP+QrwIHdTzM2WVk
YqISuFlyOzAdBgNVHQ4EFgQUYwLSXQJf943VWhKedhE2loYsikgwJQYDVR0RBB4w
HIIKZ2l0aHViLmNvbYIOd3d3LmdpdGh1Yi5jb20wDgYDVR0PAQH/BAQDAgWgMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjB1BgNVHR8EbjBsMDSgMqAwhi5o
dHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1oYS1zZXJ2ZXItZzYuY3JsMDSg
MqAwhi5odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1oYS1zZXJ2ZXItZzYu
Y3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAEBMCowKAYIKwYBBQUHAgEWHGh0dHBz
Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQICMIGDBggrBgEFBQcBAQR3
MHUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBNBggrBgEF
BQcwAoZBaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkhp
Z2hBc3N1cmFuY2VTZXJ2ZXJDQS5jcnQwDAYDVR0TAQH/BAIwADCCAXwGCisGAQQB
1nkCBAIEggFsBIIBaAFmAHUAKXm+8J45OSHwVnOfY6V35b5XfZxgCvj5TV0mXCVd
x4QAAAFx5ltprwAABAMARjBEAiAuWGCWxN/M0Ms3KOsqFjDMHT8Aq0SlHfQ68KDg
rVU6AAIgDA+2EB0D5W5r0i4Nhljx6ABlIByzrEdfcxiOD/o6//EAdQAiRUUHWVUk
VpY/oS/x922G4CMmY63AS39dxoNcbuIPAgAAAXHmW2nTAAAEAwBGMEQCIBp+XQKa
UDiPHwjBxdv5qvgyALKaysKqMF60gqem8iPRAiAk9Dp5+VBUXfSHqyW+tVShUigh
ndopccf8Gs21KJ4jXgB2AFGjsPX9AXmcVm24N3iPDKR6zBsny/eeiEKaDf7UiwXl
AAABceZbahsAAAQDAEcwRQIgd/5HcxT4wfNV8zavwxjYkw2TYBAuRCcqp1SjWKFn
4EoCIQDHSTHxnbpxWFbP6v5Y6nGFZCDjaHgd9HrzUv2J/DaacDANBgkqhkiG9w0B
AQsFAAOCAQEAhjKPnBW4r+jR3gg6RA5xICTW/A5YMcyqtK0c1QzFr8S7/l+skGpC
yCHrJfFrLDeyKqgabvLRT6YvvM862MGfMMDsk+sKWtzLbDIcYG7sbviGpU+gtG1q
B0ohWNApfWWKyNpquqvwdSEzAEBvhcUT5idzbK7q45bQU9vBIWgQz+PYULAU7KmY
z7jOYV09o22TNMQT+hFmo92+EBlwSeIETYEsHy5ZxixTRTvu9hP00CyEbiht5OTK
5EiJG6vsIh/uEtRsdenMCxV06W2f20Af4iSFo0uk6c1ryHefh08FcwA4pSNUaPyi
Pb8YGQ6o/blejFzo/OSiUnDueafSJ0p6SQ==
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
        allow_any_instance_of(HighLine).to receive(:ask).with("Enter the URL of your Conjur service: ").and_return "http://host.example.com"
        allow(Conjur::Command::Init).to receive_messages get_certificate: ["the-fingerprint", nil]
        allow_any_instance_of(HighLine).to receive(:ask).with(/^Trust this certificate/).and_return "yes"
      }

      describe_command 'init' do
        it "writes config file" do
          expect_any_instance_of(HighLine).to receive(:ask).with("Enter the URL of your Conjur service: ").and_return "http://host.example.com"
          expect_any_instance_of(HighLine).to receive(:ask).with("Enter your organization account name: ").and_return "the-account"
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

    describe_command 'init -a the-account -u https://nohost.example.com' do
      it "can't get the cert" do
        # GLI only raises CustomExit if GLI_DEBUG is set
        ENV['GLI_DEBUG'] = 'true'

        expect(TCPSocket).to receive(:new).and_raise "can't connect"
        
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
            appliance_url: "https://localhost",
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
