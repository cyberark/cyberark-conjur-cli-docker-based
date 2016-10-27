require 'spec_helper'

describe Conjur::Command::Groups, logged_in: true do
  describe_command 'group update --gidnumber 12345 some-group' do
    it "updates the gid" do
      expect_any_instance_of(Conjur::API).to \
          receive(:group).with('some-group').and_return(group = double("group"))
      expect(group).to receive(:update).with(gidnumber: 12_345)
      expect { invoke }.to write "GID set"
    end
  end

  context "lookup by GID" do
    let(:search_result) { %w(g1 g2) }
    describe_command "group gidsearch 12345" do
      it "finds the groups" do
        expect_any_instance_of(Conjur::API).to \
            receive(:find_groups).with(gidnumber: 12_345).and_return search_result
        expect { invoke }.to write(JSON.pretty_generate(search_result))
      end
    end
  end
end
