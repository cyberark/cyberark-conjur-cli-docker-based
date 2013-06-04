require 'spec_helper'

describe Conjur::Command::Authn do
  context logged_in: false do
    describe_command 'authn:whoami' do
      it "errors out" do
        expect{ invoke }.to write(/not logged in/i).to :stderr
      end
    end
  end

  context logged_in: true do
    describe_command 'authn:logout' do
      it "deletes credentials" do
        invoke
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
