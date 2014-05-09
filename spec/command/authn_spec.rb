require 'spec_helper'

describe Conjur::Command::Authn do
  context logged_in: false do
    context "logging in" do
      [ "authn:login", "authn login" ].each do |cmd|
        before do
          Conjur::Authn.stub(:write_credentials)
        end
        describe_command "#{cmd}" do
          it "prompts for username and password and logs in the user" do
            Conjur::Authn.should_receive(:ask_for_credentials).with({}).and_return [ "the-user", "the-api-key" ]
  
            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -u the-user" do
          it "prompts for password and logs in the user" do
            Conjur::Authn.should_receive(:ask_for_credentials).with({username: 'the-user'}).and_return [ "the-user", "the-api-key" ]
  
            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -u the-user -p the-password" do
          it "logs in the user" do
            Conjur::Authn.should_receive(:ask_for_credentials).with({username: 'the-user', password: 'the-password'}).and_return [ "the-user", "the-api-key" ]

            expect { invoke }.to write("Logged in")
          end
        end
        describe_command "#{cmd} -p the-password the-user" do
          it "logs in the user" do
            Conjur::Authn.should_receive(:ask_for_credentials).with({username: 'the-user', password: 'the-password'}).and_return [ "the-user", "the-api-key" ]

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

  context logged_in: true do
    describe_command 'authn:logout' do
      it "deletes credentials" do
        expect { invoke }.to write("Logged out")
        netrc[authn_host].should_not be
      end
    end

    describe_command 'authn:whoami' do
      it "prints the current account and username to stdout" do
        expect { invoke }.to write({ account: account, username: username }.to_json)
      end
    end
  end
end
