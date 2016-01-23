require "spec_helper"
require "conjur/conjurize"

describe Conjur::Conjurize do
  let(:certificate) do
    OpenSSL::X509::Certificate.new.tap do |cert|
      key = OpenSSL::PKey::RSA.new 512
      cert.public_key = key.public_key
      cert.not_before = Time.now
      cert.not_after = 1.minute.from_now
      cert.sign key, OpenSSL::Digest::SHA256.new
    end
  end

  let(:certfile) do
    Tempfile.new("cert").tap do |file|
      file.write certificate.to_pem
      file.close
    end
  end

  let(:host_id) { "somehostid" }
  let(:api_key) { "very_secret_key" }
  let(:account) { "testacct" }
  let(:appliance_url) { "https://example.com" }

  before do
    Conjur::Config.merge \
      account: account,
      cert_file: certfile.path,
      appliance_url: appliance_url
  end

  describe ".generate" do
    it "puts all the relevant data in the script" do
      script = Conjur::Conjurize.generate "id" => host_id, "api_key" => api_key
      expect(script).to include host_id, api_key, account, certificate.to_pem
    end

    it "dumps JSON if required" do
      allow(Conjur::Conjurize).to receive_messages options: { json: true }
      expect(
        JSON.load(
          Conjur::Conjurize.generate(
            "id" => host_id,
            "api_key" => api_key
          )
        )
      ).to eq \
        "id" => host_id,
        "api_key" => api_key,
        "account" => account,
        "certificate" => certificate.to_pem.strip,
        "appliance_url" => appliance_url
    end
  end

  describe ".configuration" do
    it "gathers all the configuration options" do
      expect(
        Conjur::Conjurize.configuration("id" => host_id, "api_key" => api_key)
      ).to eq \
        "id" => host_id,
        "api_key" => api_key,
        "account" => account,
        "certificate" => certificate.to_pem.strip,
        "appliance_url" => appliance_url
    end
  end
end
