shared_context "default audit behavior" do
  let(:common_prefix) { "[#{default_audit_event["timestamp"]}] #{default_audit_event["user"]}" }

  let(:default_audit_event) {
    {
      "request" => {
                  "ip" => "1.2.3.4",
                  "url"=>"https://conjur/api",
                  "method"=>"POST",
                  "uuid" => "abcdef",
                  "params"=> {
                    "controller"=>"role",
                    "action"=>"create",
                    "account"=>"the-account"
                    }
                  },
      "acting_as" => "account:group:admins",
      "conjur" =>   { # new behaviour
                  "user" => "account:user:alice",
                  "role" => "account:group:admins",
                  "domain" => "authz",
                  "env"    => "test",
                  "account" => "the-account"
                  },
      "completely_custom_field" => "with some value",
      "kind" => "some_asset",
      "action" => "some_action",
      "user" => "account:user:alice",
      "id"   => 12345,
      "timestamp" => Time.now().to_s,
      "event_id" => "xaxaxaxaxa",
      "resources" => ["the-account:layer:resources/production", "layer:resources/frontend"],
      "roles" => ["the-account:group:roles/qa", "group:roles/ssh_users"]
    }
  }

  shared_examples_for "it supports standard prefix:" do
    describe "if acting_as is the same as user" do
      let(:audit_event) { test_event.tap { |e| e["acting_as"]=e["user"] } }
      it "prints default prefix" do
        expect { invoke }.to write(common_prefix)
      end
      it "does not print 'acting_as' statement" do
        expect { invoke }.to_not write(common_prefix+" (as ")
      end
    end

    describe "if acting_as is different from user" do
      it 'prints default prefix followed by (acting as..) statement' do
        expect { invoke }.to write(common_prefix+" (as #{audit_event['acting_as']})")
      end
    end
  end

  shared_examples_for "it recognizes error messages:" do
    describe "if :error is not empty" do
      let(:audit_event) { test_event.merge("error"=>"everything's down") }
      it 'appends (failed with...) statement' do
        expect { invoke }.to write(" (failed with everything's down)")
      end
    end
    describe "if :error is empty" do
      it 'does not print "failed with" statement' do
        expect { invoke }.not_to write(" (failed with ")
      end
    end
  end
end
