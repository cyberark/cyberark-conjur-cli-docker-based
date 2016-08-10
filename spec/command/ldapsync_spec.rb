require 'spec_helper'

describe Conjur::Command::LDAPSync, logged_in: true do
  let(:timestamp) { Time.now.to_s }
  let(:json_response) { {
      'events' => [
        { "timestamp" => timestamp,
          "severity" => "info",
          "message" => "Performing sync"
        }
      ],
      'result' => {
        'actions' => [
            "user 'Guest'", "group 'Domain Computers'"
        ]
      }
  } }
  let(:yaml_response) { [
      'annotations' => {
          'ldap-sync/source' => '192.168.99.100:389',
          'ldap-sync/upstream-dn' => 'cn=Guest,dc=example,dc=org',
      }
  ].to_yaml }



  context 'when testing ldap-sync jobs commands' do
    let(:jobs){
      [
          Conjur::LdapSyncJob.new(api, 'job-1', 'sync', 'running', true),
          Conjur::LdapSyncJob.new(api, 'job-2', 'connect', 'success', false)
      ]
    }

    before do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_jobs).and_return jobs
    end

    describe_command 'ldap-sync jobs list' do
      it 'prints the jobs as json' do
        expect { invoke }.to write(JSON.pretty_generate jobs.map(&:as_json))
      end
    end

    describe_command 'ldap-sync jobs list -i' do
      it 'prints the job ids only' do
        expect { invoke }.to write(JSON.pretty_generate jobs.map(&:id))
      end
    end

    describe_command 'ldap-sync jobs list -f pretty' do

      it 'prints the jobs in a fancy table' do
        expect{ invoke }.to write /ID\s*|\s*TYPE\s*|\s*STATE\s*|\s*EXCLUSIVE.*?
job-1\s*|\s*sync\s*|\s*running\s*|\s*true
job-2\s*|\s*connect\s*|\s*success\s*|\s*false/x
      end
    end


    describe_command 'ldap-sync jobs delete job-2' do
      let(:victim){ jobs[1] }
      it 'deletes the job' do
        expect(victim).to receive(:delete)
        invoke
      end
    end

    describe_command 'ldap-sync jobs delete no-such-job' do
      it 'fails with a sensible error message' do
        expect{ invoke }.to raise_exception(/No job found with ID 'no-such-job'/)
      end
    end

    describe_command 'ldap-sync jobs output job-1' do
      let(:victim){ jobs[0] }
      it 'prints the values passed to output' do
        expect(victim).to receive(:output) do |&block|
          block.call({foo: 'bar'})
          block.call({spam: 'eggs'})
        end

        expect{invoke}.to write(<<EOS)
{
  "foo": "bar"
}
{
  "spam": "eggs"
}
EOS

      end
    end
  end

  describe_command 'ldap-sync now -f text' do
    before {
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return json_response
    }
    it 'prints out diagnostic events' do
      expect { invoke }.to write([ timestamp, "info", "Performing sync" ].join("\t"))
    end
    it 'prints out actions as text' do
      expect { invoke }.to write("user 'Guest'\ngroup 'Domain Computers'")
    end
  end

  describe_command 'ldap-sync now -f yaml' do
    it 'prints out actions as unparsed yaml' do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now).and_return yaml_response
      expect { invoke }.to write(yaml_response)
    end
  end

  context 'when testing dry-run' do
    before do
      expect_any_instance_of(Conjur::API).to receive(:ldap_sync_now)
                                              .with('default', 'application/json', dry_run)
                                              .and_return json_response
    end

    describe_command 'ldap-sync now' do
      let(:dry_run) { false }
      it 'passes falsey dry-run value' do
        invoke
      end
    end

    describe_command 'ldap-sync now --no-dry-run' do
      let(:dry_run) { false }
      it 'passes falsey dry-run value' do
        invoke
      end
    end

    describe_command 'ldap-sync now --dry-run' do
      let(:dry_run) { true }
      it 'passes truthy dry-run value' do
        invoke
      end
    end
  end
end
