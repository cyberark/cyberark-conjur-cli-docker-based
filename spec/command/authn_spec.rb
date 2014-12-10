require 'spec_helper'

describe Conjur::Command::Authn do
  context "when not logged in", logged_in: false do
    context "logging in" do
      [ "authn:login", "authn login" ].each do |cmd|
        before do
          allow(Conjur::Authn).to receive(:write_credentials)
        end
        describe_command "#{cmd}" do
          it "prompts for username and password and logs in the user" do
            expect(Conjur::Authn).to receive(:ask_for_credentials).with({}).and_return [ "the-user", "the-api-key" ]
  
            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -u the-user" do
          it "prompts for password and logs in the user" do
            expect(Conjur::Authn).to receive(:ask_for_credentials).with({username: 'the-user'}).and_return [ "the-user", "the-api-key" ]
  
            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -u the-user -p the-password" do
          it "logs in the user" do
            expect(Conjur::Authn).to receive(:ask_for_credentials).with({username: 'the-user', password: 'the-password'}).and_return [ "the-user", "the-api-key" ]

            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -p the-password the-user" do
          it "logs in the user" do
            expect(Conjur::Authn).to receive(:ask_for_credentials).with({username: 'the-user', password: 'the-password'}).and_return [ "the-user", "the-api-key" ]

            expect { invoke }.to write("Logged in")
          end
        end
      end
    end

    describe_command 'authn:whoami' do
      it "errors out" do
        expect { invoke }.to raise_error(GLI::CustomExit, /not logged in/i)
      end
    end
  end
  
  context "when login credentials are available in the environment" do
    before do
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_LOGIN").and_return username
      expect(ENV).to receive(:[]).with("CONJUR_AUTHN_API_KEY").and_return 'the-password'
      it "prints the current account and username to stdout" do
        expect { invoke }.to write({ account: account, username: username }.to_json)
      end
    end
  end

  context "when logged in", logged_in: true do
    describe_command 'authn:logout' do
      it "deletes credentials" do
        expect { invoke }.to write("Logged out")
        expect(netrc[authn_host]).not_to be
      end
    end

    describe_command 'authn:whoami' do
      it "prints the current account and username to stdout" do
        expect { invoke }.to write({ account: account, username: username }.to_json)
      end
    end
  end
end
