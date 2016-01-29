require 'spec_helper'

describe Conjur::Command::Hosts, logged_in: true do
  let(:collection_url) { "https://core.example.com/api/hosts" }

  context "creating a host" do
    let(:new_host) { double("new-host") }

    describe_command "host:create" do
      it "lets the server assign the id" do
       expect(RestClient::Request).to receive(:execute).with({
          method: :post,
          url: collection_url,
          headers: {},
          payload: {}
          }).and_return(post_response('assigned-id'))

        expect { invoke }.to write({ id: 'assigned-id' }).to(:stdout)
      end
    end
    describe_command "host:create the-id" do
      it "propagates the user-assigned id" do
       expect(RestClient::Request).to receive(:execute).with({
          method: :post,
          url: collection_url,
          headers: {},
          payload: { id: 'the-id' }
        }).and_return(post_response('the-id'))

        expect { invoke }.to write({ id: 'the-id' }).to(:stdout)
      end
    end
    describe_command "host:create --cidr 192.168.1.1,127.0.0.0/32" do
      it "Creates a host with specified CIDR" do
        expect_any_instance_of(Conjur::API).to receive(:create_host).with(
            { cidr: ['192.168.1.1', '127.0.0.0/32'] }
        ).and_return new_host
        invoke
      end
    end
    describe_command "host:create --as-group security_admin --cidr 192.168.1.1,127.0.0.0/32" do
      it "Creates a host with specified CIDR" do
        expect(api).to receive(:group).with("security_admin").and_return(double(:group, roleid: "the-account:group:security_admin"))
        expect(api).to receive(:role).with("the-account:group:security_admin").and_return(double(:group_role, exists?: true))
        expect_any_instance_of(Conjur::API).to receive(:create_host).with(
            { ownerid: "the-account:group:security_admin", cidr: ['192.168.1.1', '127.0.0.0/32'] }
        ).and_return new_host
        invoke
      end
    end
  end

  context "updating host attributes" do
    describe_command "host update --cidr 127.0.0.0/32 the-user" do
      it "updates the CIDR" do
        stub_host = double()
        expect_any_instance_of(Conjur::API).to receive(:host).with("the-user").and_return stub_host
        expect(stub_host).to receive(:update).with(cidr: ['127.0.0.0/32']).and_return ""
        expect { invoke }.to write "Host updated"
      end
    end

    describe_command "host update --cidr all the-user" do
      it "resets the CIDR restrictions" do
        stub_host = double()
        expect_any_instance_of(Conjur::API).to receive(:host).with("the-user").and_return stub_host
        expect(stub_host).to receive(:update).with(cidr: []).and_return ""
        expect { invoke }.to write "Host updated"
      end
    end
  end
end
