require 'spec_helper'
require 'highline'

GITHUB_FP = "SHA1 Fingerprint=A3:B5:9E:5F:E8:84:EE:1F:34:D9:8E:EF:85:8E:3F:B6:62:AC:10:4A"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIFajCCBPGgAwIBAgIQDNCovsYyz+ZF7KCpsIT7HDAKBggqhkjOPQQDAzBWMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMTAwLgYDVQQDEydEaWdp
Q2VydCBUTFMgSHlicmlkIEVDQyBTSEEzODQgMjAyMCBDQTEwHhcNMjMwMjE0MDAw
MDAwWhcNMjQwMzE0MjM1OTU5WjBmMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2Fs
aWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzEVMBMGA1UEChMMR2l0SHVi
LCBJbmMuMRMwEQYDVQQDEwpnaXRodWIuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAEo6QDRgPfRlFWy8k5qyLN52xZlnqToPu5QByQMog2xgl2nFD1Vfd2Xmgg
nO4i7YMMFTAQQUReMqyQodWq8uVDs6OCA48wggOLMB8GA1UdIwQYMBaAFAq8CCkX
jKU5bXoOzjPHLrPt+8N6MB0GA1UdDgQWBBTHByd4hfKdM8lMXlZ9XNaOcmfr3jAl
[BgNVHREEHjAcggpnaXRodWIuY29tgg53d3cuZ2l0aHViLmNvbTAOBgNVHQ8BAf8E
BAMCB4AwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMIGbBgNVHR8EgZMw
gZAwRqBEoEKGQGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5
YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5jcmwwRqBEoEKGQGh0dHA6Ly9jcmw0LmRp
Z2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5j
cmwwPgYDVR0gBDcwNTAzBgZngQwBAgIwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3
dy5kaWdpY2VydC5jb20vQ1BTMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGG
GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2Nh
Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTSHlicmlkRUNDU0hBMzg0MjAy
MENBMS0xLmNydDAJBgNVHRMEAjAAMIIBgAYKKwYBBAHWeQIEAgSCAXAEggFsAWoA
dwDuzdBk1dsazsVct520zROiModGfLzs3sNRSFlGcR+1mwAAAYZQ3Rv6AAAEAwBI
MEYCIQDkFq7T4iy6gp+pefJLxpRS7U3gh8xQymmxtI8FdzqU6wIhALWfw/nLD63Q
YPIwG3EFchINvWUfB6mcU0t2lRIEpr8uAHYASLDja9qmRzQP5WoC+p0w6xxSActW
3SyB2bu/qznYhHMAAAGGUN0cKwAABAMARzBFAiAePGAyfiBR9dbhr31N9ZfESC5G
V2uGBTcyTyUENrH3twIhAPwJfsB8A4MmNr2nW+sdE1n2YiCObW+3DTHr2/UR7lvU
AHcAO1N3dT4tuYBOizBbBv5AO2fYT8P0x70ADS1yb+H61BcAAAGGUN0cOgAABAMA
SDBGAiEAzOBr9OZ0+6OSZyFTiywN64PysN0FLeLRyL5jmEsYrDYCIQDu0jtgWiMI
KU6CM0dKcqUWLkaFE23c2iWAhYAHqrFRRzAKBggqhkjOPQQDAwNnADBkAjAE3A3U
3jSZCpwfqOHBdlxi9ASgKTU+wg0qw3FqtfQ31OwLYFdxh0MlNk/HwkjRSWgCMFbQ
vMkXEPvNvv4t30K6xtpG26qmZ+6OiISBIIXMljWnsiYR1gyZnTzIg3AQSw4Vmw==
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
