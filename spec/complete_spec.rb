require 'spec_helper'

describe Conjur::CLI::Complete do
  def expects_completions_for string, point=nil
    expect(described_class.new("conjur #{string}",point)
            .completions
            .map { |c| c.chomp ' ' })
  end

  describe 'conjur bash completion' do
    describe 'for conjur subcommands beginning' do

      before(:each) { expect(Conjur::Command).not_to receive :api }

      context 'with "conjur gr"' do
        it { expects_completions_for('gr').to include 'group' }
      end

      context 'with "conjur group"' do
        it { expects_completions_for('group').to contain_exactly 'group' }
      end

      context 'with "conjur p"' do
        it { expects_completions_for('p').to include 'plugin',
                                                     'policy',
                                                     'pubkeys' }
      end

      context 'with "conjur host l"' do
        it { expects_completions_for('host l').to include 'layers',
                                                          'list' }
      end

      context 'with "conjur policy"' do
        it { expects_completions_for('policy ').to include 'load' }
      end
    end

    describe 'for deprecated subcommands such as `conjur field`' do
      it { expects_completions_for('fi').not_to include 'field' }
    end

    describe 'for command flags beginning' do

      before(:each) { expect(Conjur::Command).not_to receive :api }

      context 'conjur -' do
        it { expects_completions_for('-').to include '--version' }
      end

      context 'conjur role memberships -' do
        it { expects_completions_for('role memberships -')
             .to include '-s', '--system'}
      end

      context 'conjur audit all -' do
        it { expects_completions_for('audit all -s -')
             .to include '-f', '--follow', '-l', '--limit=',
                         '-o', '--offset=', '-s', '--short' }
      end

      context 'conjur layer create --as-' do
        it { expects_completions_for('layer create --as-')
             .to include '--as-role=' }
      end

      context 'conjur group create --as-role' do
        it { expects_completions_for('layer create --as-role')
             .to contain_exactly '--as-role=' }
      end
    end

    describe 'for arguments' do

      let (:api) { double('api') }
      before(:each) {
        expect(Conjur::Command).to receive(:api).at_least(:once).and_return api
      }

      describe 'expecting a resource' do

        let (:users) { ['Tweedledum', 'Tweedledee'] }
        let (:groups) { ['sharks', 'jets'] }
        let (:layers) { ['limbo', 'lust', 'gluttony', 'greed',
                           'anger', 'heresy', 'violence', 'fraud',
                           'treachery'] }
        let (:variables) { ['id/superman', 'id/batman', 'id/spiderman'] }
        let (:hosts) { ['skynet', 'hal9000', 'deep-thought'] }


        def mock_resources
          fake_results = yield.map { |result|
            double('resource', :attributes => { 'id' => result })
          }
          expect(Conjur::Command.api).to receive(:resources)
                                          .once.and_return fake_results
        end

        context 'with kind "user"' do
          before(:each) { mock_resources { users.map { |user| "user:#{user}" }}}
          it { expects_completions_for('user show ')
               .to contain_exactly(*users) }
        end

        context 'with kind "group"' do
          before(:each) {
            mock_resources { groups.map { |group| "group:#{group}" }}
          }
          context 'for a command' do
            it { expects_completions_for('group show ')
                 .to contain_exactly(*groups) }
          end
          context 'for a flag' do
            it { expects_completions_for('group create --as-group=')
                 .to contain_exactly(*groups) }
          end
        end

        context 'with kind "layer"' do
          before(:each) {
            mock_resources { layers.map { |layer| "layer:#{layer}" }}
          }
          it { expects_completions_for('layer show ')
               .to contain_exactly(*layers) }
        end

        context 'with kind "variable"' do
          before(:each) {
            mock_resources { variables.map { |variable| "variable:#{variable}" }}
          }
          it { expects_completions_for('variable show ')
               .to contain_exactly(*variables) }
        end

        context 'with kind "host"' do
          before(:each) {
            mock_resources { hosts.map { |host| "host:#{host}" }}
          }
          it { expects_completions_for('host show ')
               .to contain_exactly(*hosts)
          }
        end

        context 'without kind specified' do
          let (:resources) { (users+groups+layers+variables+hosts)
                             .map { |res| "arbitrarykind:#{res}" }}
          before(:each) { mock_resources { resources }}
          it 'should show all resources with their reported kinds' do
            expects_completions_for('resource show ')
               .to contain_exactly(*resources)
          end
        end
      end

      describe 'expecting a role' do
        let (:roles) { ['layer:population/tire',
                        'host:bubs-4k',
                        'user:strongbad',
                        'user:strongsad',
                        'user:strongmad']}
        before(:each) {
          role_doubles = roles.map { |role| double('role', :roleid => role) }
          expect(api).to receive(:current_role).once
                          .and_return double('current_role', :all => role_doubles)
        }
        it { expects_completions_for('role memberships ')
             .to contain_exactly(*roles) }
        it 'completes colon separated values per-token' do
          expects_completions_for('layer list --role=host:b')
            .to contain_exactly 'bubs-4k'
        end
        it 'recognizes shell-escaped colons' do
          expects_completions_for('role members layer\:pop')
            .to contain_exactly 'layer:population/tire'
        end
      end
    end

    describe 'completes mid-line' do
      it 'completes a subcommand not at the end of a line' do
        expect(described_class.new('conjur gr create dwarves/7', 9).completions)
          .to include 'group '
      end
      it 'tolerates garbage flags and arguments' do
        expect(described_class.new('conjur omg --lol wat pu').completions)
          .to include 'pubkeys '
        end
    end
  end
end

describe Conjur::CLI::Complete::Resource do
  describe 'splits resource ids' do
    describe '#initialize(resource_string)' do
      describe 'accepts long or brief ids' do
        context 'gratuitous id (4+ tokens)' do
          it 'raises an ArgumentError' do
            expect {
              described_class.new '1:2:3:4'
            }.to raise_error ArgumentError
          end
        end
        context 'long id (3 tokens)' do
          it 'stores all 3 tokens' do
            dummy_string = 'acct:kind:name'
            dummy = described_class.new dummy_string
            expect(dummy.account).to eq 'acct'
            expect(dummy.kind).to eq 'kind'
            expect(dummy.name).to eq 'name'
          end
        end
        context 'brief id (2 tokens)' do
          it 'stores tokens in kind and name' do
            dummy = described_class.new 'kind:name'
            expect(dummy.account).to eq nil
            expect(dummy.kind).to eq 'kind'
            expect(dummy.name).to eq 'name'
          end
        end
        context 'tiny id (1 token)' do
          it 'stores token in name' do
            dummy = described_class.new 'name'
            expect(dummy.account).to eq nil
            expect(dummy.kind).to eq nil
            expect(dummy.name).to eq 'name'
          end
        end
      end
      it 'hides the account by default' do
        expect(described_class.new('a:b:c').include_account).to eq false
        expect(described_class.new('a:b:c', true).include_account).to eq true
      end
    end

    describe '#to_ary' do
      context 'account not important' do
        it 'hides account when converting to array' do
          dummy = described_class.new 'a:b:c'
          expect(dummy.to_ary).to eq ['b','c']
        end
      end
      context 'account is important' do
        it 'includes account when converting to array' do
          dummy = described_class.new 'a:b:c', true
          expect(dummy.to_ary).to eq ['a','b','c']
        end
      end
    end

    describe '#to_s' do
      context 'account not important' do
        it 'hides account when converting to string' do
          dummy = described_class.new 'test:user:admin'
          expect(dummy.to_s).to eq 'user:admin'
        end
      end
      context 'account is important' do
        it 'includes account when converting to string' do
          dummy = described_class.new 'test:user:admin', true
          expect(dummy.to_s).to eq 'test:user:admin'
        end
      end
    end
  end
end
