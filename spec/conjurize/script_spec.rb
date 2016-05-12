require "spec_helper"
require "conjur/conjurize/script"

describe Conjur::Conjurize::Script do
  describe ".latest_conjur_cookbook_release" do
    let(:releases_json) do
      %([
        {
          "name": "v0.4.0",
          "assets": [{
            "name": "conjur-v0.4.0.tar.gz",
            "browser_download_url": "http://example.com/conjur-v0.4.0.tar.gz"
          }]
        },
        {
          "name": "v0.3.0",
          "assets": [{
            "name": "conjur-v0.3.0.tar.gz",
            "browser_download_url": "http://example.com/conjur-v0.3.0.tar.gz"
          }]
        }
      ])
    end

    before do
      allow(Conjur::Conjurize::Script).to receive(:open)\
        .with("https://api.github.com/repos/conjur-cookbooks/conjur/releases")\
        .and_return double(read: releases_json)
    end

    it "looks up the latest release download url" do
      expect(Conjur::Conjurize::Script.latest_conjur_cookbook_release).to \
        eq "http://example.com/conjur-v0.4.0.tar.gz"
    end

    context "with latest release is without any tarballs" do
      let(:releases_json) do
        %([
          {
            "name": "v0.4.0",
            "assets": []
          },
          {
            "name": "v0.3.0",
            "assets": [{
              "name": "conjur-v0.3.0.tar.gz",
              "browser_download_url": "http://example.com/conjur-v0.3.0.tar.gz"
            }]
          }
        ])
      end

      it "returns the previous one and warns" do
        err = $stderr.grab do
          expect(Conjur::Conjurize::Script.latest_conjur_cookbook_release).to \
            eq "http://example.com/conjur-v0.3.0.tar.gz"
        end
        expect(err).to include "WARNING"
      end
    end
  end
end
