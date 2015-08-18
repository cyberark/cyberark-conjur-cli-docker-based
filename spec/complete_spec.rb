require 'spec_helper'

describe Conjur::CLI::Complete do
  it 'completes' do
    expect(described_class.new('conjur gr').completions).to eq ['group ']
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

    describe '#shellescape' do
      it 'uses \: instead of : as a separator' do
        fields = 'first', 'second'
        dummy = described_class.new fields.join(':')
        expect(dummy.shellescape).to eq fields.join('\:')
      end
    end
  end
end
