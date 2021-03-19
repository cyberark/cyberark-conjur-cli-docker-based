require 'spec_helper'
require 'highline'

GITHUB_FP = "SHA1 Fingerprint=54:C5:A2:27:06:92:CF:D1:1C:24:A3:92:96:41:49:06:21:B0:45:30"
GITHUB_CERT = <<EOF
-----BEGIN CERTIFICATE-----
MIIEQzCCAyugAwIBAgIQCidf5wTW7ssj1c1bSxpOBDANBgkqhkiG9w0BAQwFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0yMDA5MjMwMDAwMDBaFw0zMDA5MjIyMzU5NTlaMFYxCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxMDAuBgNVBAMTJ0RpZ2lDZXJ0IFRMUyBI
eWJyaWQgRUNDIFNIQTM4NCAyMDIwIENBMTB2MBAGByqGSM49AgEGBSuBBAAiA2IA
BMEbxppbmNmkKaDp1AS12+umsmxVwP/tmMZJLwYnUcu/cMEFesOxnYeJuq20ExfJ
qLSDyLiQ0cx0NTY8g3KwtdD3ImnI8YDEe0CPz2iHJlw5ifFNkU3aiYvkA8ND5b8v
c6OCAa4wggGqMB0GA1UdDgQWBBQKvAgpF4ylOW16Ds4zxy6z7fvDejAfBgNVHSME
GDAWgBQD3lA1VtFMu2bwo+IbG8OXsj3RVTAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0l
BBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMBIGA1UdEwEB/wQIMAYBAf8CAQAwdgYI
KwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
b20wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
Q2VydEdsb2JhbFJvb3RDQS5jcnQwewYDVR0fBHQwcjA3oDWgM4YxaHR0cDovL2Ny
bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdENBLmNybDA3oDWgM4Yx
aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdENBLmNy
bDAwBgNVHSAEKTAnMAcGBWeBDAEBMAgGBmeBDAECATAIBgZngQwBAgIwCAYGZ4EM
AQIDMA0GCSqGSIb3DQEBDAUAA4IBAQDeOpcbhb17jApY4+PwCwYAeq9EYyp/3YFt
ERim+vc4YLGwOWK9uHsu8AjJkltz32WQt960V6zALxyZZ02LXvIBoa33llPN1d9R
JzcGRvJvPDGJLEoWKRGC5+23QhST4Nlg+j8cZMsywzEXJNmvPlVv/w+AbxsBCMqk
BGPI2lNM8hkmxPad31z6n58SXqJdH/bYF462YvgdgbYKOytobPAyTgr3mYI5sUje
CzqJx1+NLyc8nAK8Ib2HxnC+IrrWzfRLvVNve8KaN9EtBH7TuMwNW4SpDCmGr6fY
1h3tDjHhkTb9PA36zoaJzu0cIw265vZt6hCmYWJC+/j+fgZwcPwL
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
