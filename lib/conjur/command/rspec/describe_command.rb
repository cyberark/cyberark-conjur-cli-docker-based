RSpec::Core::DSL.change_global_dsl do
  def describe_command *argv, &block
    describe *argv do
      let(:cert_store) { double(:cert_store) }
        
      before do
        allow(cert_store).to receive(:add_file)
        stub_const 'OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE', cert_store
      end
      
      let(:cert_store_options) do
        {
          ssl_cert_store: cert_store
        }
      end
      
      let(:invoke) do
        Conjur::CLI.error_device = $stderr
        # TODO: allow proper handling of description like "audit:send 'hello world'"
        Conjur::CLI.run argv.first.split(' ')
      end
      instance_eval &block
    end
  end
end
