require 'spec_helper'
require 'conjur/command/variables'

describe Conjur::Command::Variables, :logged_in => true do
  let (:variable) { double(:name => 'foo') }
  let (:incompatible_server_msg) { /not supported/ }
  
  context "expiring a variable" do
    
    let (:duration) { nil }

    context "with valid arguments" do 
      before do
        expect(RestClient::Request).to receive(:execute).with({
            :method => :post,
            :url => 'https://core.example.com/api/variables/foo/expiration',
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
            :url => 'https://core.example.com/api/variables/expirations',
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
  end

  let(:certificate) do
    OpenSSL::X509::Certificate.new.tap do |cert|
      key = OpenSSL::PKey::RSA.new 512
      cert.public_key = key.public_key
      cert.not_before = Time.now
      cert.not_after = 1.minute.from_now
      cert.sign key, OpenSSL::Digest::SHA256.new
    end
  end

  let(:certfile) do
    Tempfile.new("cert").tap do |file|
      file.write certificate.to_pem
      file.close
    end
  end

  context 'connecting to incompatible server version while' do
    before do
      allow(Conjur.config).to receive_messages \
                              cert_file: certfile.path,
                              appliance_url: core_host

      expect(RestClient::Request).to receive(:execute).with({
          :method => :get,
          :url => "https://core.example.com/info",
          :headers => {}
      }).and_raise(RestClient::ResourceNotFound)
    end

    context 'setting variable expiration' do
      describe_command 'variable:expire --days 1 foo' do
        it 'should display error message' do
          expect(RestClient::Request).to receive(:execute).with({
              :method => :post,
              :url => "https://core.example.com/api/variables/foo/expiration",
              :headers => {},
              :payload => anything
          }).and_raise(RestClient::ResourceNotFound)
          expect { invoke }.to raise_error(RestClient::ResourceNotFound)
                           .and write(incompatible_server_msg).to(:stderr)
        end
      end
    end

    context 'getting variable expirations' do
      describe_command 'variable:expirations' do
        it 'should display error message' do
          expect(RestClient::Request).to receive(:execute).with({
              :method => :get,
              :url => 'https://core.example.com/api/variables/expirations',
              :headers => {}
          }).and_raise(RestClient::ResourceNotFound)
          expect { invoke }.to raise_error(RestClient::ResourceNotFound)
                           .and write(incompatible_server_msg).to(:stderr)
        end
      end
    end
  end
end
