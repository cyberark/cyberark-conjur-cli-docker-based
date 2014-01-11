require 'conjur/authn'
require 'conjur/config'

describe Conjur::Authn do
  describe "netrc" do
    before {
      Conjur::Authn.instance_variable_set("@netrc", nil)
      Conjur::Config.should_receive(:[]).with(:netrc_path).and_return path
    }
    after {
      Conjur::Authn.instance_variable_set("@netrc", nil)
    }
    context "with specified netrc_path" do
      let(:path) { double("path") }
      it "consults Conjur::Config for netrc_path" do
        Netrc.should_receive(:read).with(path).and_return netrc = double("netrc")
        Conjur::Authn.netrc.should == netrc
      end
    end
    context "without specified netrc_path" do
      let(:path) { nil }
      it "uses default netrc path" do
        Netrc.should_receive(:read).with().and_return netrc = double("netrc")
        Conjur::Authn.netrc.should == netrc
      end
    end
  end
end
