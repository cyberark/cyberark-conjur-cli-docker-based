require 'spec_helper'
require 'conjur/command/variables'

describe Conjur::Command::Variables, :logged_in => true do
  def invoke_silently
    real_stderr = $stderr
    $stderr = StringIO.new
    begin
      invoke
    ensure
      $stderr = real_stderr
    end
  end

  let (:variable) { double(:name => 'foo') }
  
  context "expiring a variable" do
    
    let (:duration) { nil }

    context "with valid arguments" do 
      before do
        expect(RestClient::Request).to receive(:execute).with({
            :method => :post,
            :url => 'https://core.example.com/variables/foo/expiration',
            :headers => {},
            :payload => {:duration => duration}
          }).and_return(double('response', :body => '{}'))
      end
      
      shared_examples 'it sets variable expiration' do 
        it do
          expect {invoke}.to write
        end
      end
      
      describe_command 'variable:expire --now foo' do
        let (:duration) { 'P0Y' }
        it_behaves_like 'it sets variable expiration'
      end
      
      describe_command 'variable:expire --days 1 foo' do
        let (:duration) { 'P1D' }
        it_behaves_like 'it sets variable expiration'
      end
      
      describe_command 'variable:expire --months 1 foo' do
        let (:duration) { 'P1M' }
        it_behaves_like 'it sets variable expiration'
      end

      describe_command 'variable:expire --in PT1M foo' do
        let (:duration) { 'PT1M' }
        it_behaves_like 'it sets variable expiration'
      end

    end

    describe_command 'variable:expire --now --days 1 foo' do
      it "fails" do
        expect { invoke_silently }.to raise_error GLI::CustomExit
      end

    end

    describe_command 'variable:expire' do
      it 'should fail' do
        expect { invoke_silently }.to raise_error RuntimeError
      end
    end

  end

  context "getting variable expirations" do
    context "with valid arguments" do
      let (:expected_params) { nil }
      let (:expected_headers) { {}.tap {|h| h.merge!(:params => expected_params) if expected_params} }
      before do
        expect(RestClient::Request).to receive(:execute).with({
            :method => :get,
            :url => 'https://core.example.com/variables/expirations',
            :headers => expected_headers
          }).and_return(double('response', :body => '[]'))
      end

      shared_examples 'it writes expiration list' do
        it do
          expect { invoke }.to write "[\n\n]\n"
        end
      end

      describe_command 'variable:expirations' do
        it_behaves_like 'it writes expiration list' 
      end

      describe_command 'variable:expirations --days 1' do
        let (:expected_params) { { :duration => 'P1D' } }
        it_behaves_like 'it writes expiration list' 
      end

      describe_command 'variable:expirations --months 1' do
        let (:expected_params) { { :duration => 'P1M' } }
        it_behaves_like 'it writes expiration list' 
      end

      describe_command 'variable:expirations --in P1D' do
        let (:expected_params) { { :duration => 'P1D' } }
        it_behaves_like 'it writes expiration list' 
      end

    end

    context "with invalid arguments" do
      describe_command 'variable:expirations --days 1 --months 1' do
        it 'should fail' do
          expect { invoke_silently }.to raise_error GLI::CustomExit
        end
      end
    end

  end
    
end
