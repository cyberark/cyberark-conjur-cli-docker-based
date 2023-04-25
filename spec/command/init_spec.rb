require 'spec_helper'
require 'highline'

GITHUB_FP = "SHA1 Fingerprint=1E:16:CC:3F:84:2F:65:FC:C0:AB:93:2D:63:8A:C6:4A:95:C9:1B:7A"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIFajCCBPCgAwIBAgIQBRiaVOvox+kD4KsNklVF3jAKBggqhkjOPQQDAzBWMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMTAwLgYDVQQDEydEaWdp
Q2VydCBUTFMgSHlicmlkIEVDQyBTSEEzODQgMjAyMCBDQTEwHhcNMjIwMzE1MDAw
MDAwWhcNMjMwMzE1MjM1OTU5WjBmMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2Fs
aWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzEVMBMGA1UEChMMR2l0SHVi
LCBJbmMuMRMwEQYDVQQDEwpnaXRodWIuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAESrCTcYUh7GI/y3TARsjnANwnSjJLitVRgwgRI1JlxZ1kdZQQn5ltP3v7
KTtYuDdUeEu3PRx3fpDdu2cjMlyA0aOCA44wggOKMB8GA1UdIwQYMBaAFAq8CCkX
jKU5bXoOzjPHLrPt+8N6MB0GA1UdDgQWBBR4qnLGcWloFLVZsZ6LbitAh0I7HjAl
BgNVHREEHjAcggpnaXRodWIuY29tgg53d3cuZ2l0aHViLmNvbTAOBgNVHQ8BAf8E
BAMCB4AwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMIGbBgNVHR8EgZMw
gZAwRqBEoEKGQGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5
YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5jcmwwRqBEoEKGQGh0dHA6Ly9jcmw0LmRp
Z2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5j
cmwwPgYDVR0gBDcwNTAzBgZngQwBAgIwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3
dy5kaWdpY2VydC5jb20vQ1BTMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGG
GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2Nh
Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTSHlicmlkRUNDU0hBMzg0MjAy
MENBMS0xLmNydDAJBgNVHRMEAjAAMIIBfwYKKwYBBAHWeQIEAgSCAW8EggFrAWkA
dgCt9776fP8QyIudPZwePhhqtGcpXc+xDCTKhYY069yCigAAAX+Oi8SRAAAEAwBH
MEUCIAR9cNnvYkZeKs9JElpeXwztYB2yLhtc8bB0rY2ke98nAiEAjiML8HZ7aeVE
P/DkUltwIS4c73VVrG9JguoRrII7gWMAdwA1zxkbv7FsV78PrUxtQsu7ticgJlHq
P+Eq76gDwzvWTAAAAX+Oi8R7AAAEAwBIMEYCIQDNckqvBhup7GpANMf0WPueytL8
u/PBaIAObzNZeNMpOgIhAMjfEtE6AJ2fTjYCFh/BNVKk1mkTwBTavJlGmWomQyaB
AHYAs3N3B+GEUPhjhtYFqdwRCUp5LbFnDAuH3PADDnk2pZoAAAF/jovErAAABAMA
RzBFAiEA9Uj5Ed/XjQpj/MxQRQjzG0UFQLmgWlc73nnt3CJ7vskCICqHfBKlDz7R
EHdV5Vk8bLMBW1Q6S7Ga2SbFuoVXs6zFMAoGCCqGSM49BAMDA2gAMGUCMCiVhqft
7L/stBmv1XqSRNfE/jG/AqKIbmjGTocNbuQ7kt1Cs7kRg+b3b3C9Ipu5FQIxAM7c
tGKrYDGt0pH8iF6rzbp9Q4HQXMZXkNxg+brjWxnaOVGTDNwNH7048+s/hT9bUQ==
EOF

describe Conjur::Command::Init do
  describe ".get_certificate" do
    it "returns the right certificate from github" do
      fingerprint, certificate = Conjur::Command::Init.get_certificate('github.com:443')
      print "------------"
      print fingerprint
      print "------------"
      print certificate
      print "------------"
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
