RSpec::Core::DSL.change_global_dsl do
  def describe_command *argv, &block
    describe *argv do
      let(:cert_store) { double(:cert_store) }
        
      before do
        allow(cert_store).to receive(:add_file)
        # Stub the constant OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE which is
        # implicitly used in many places in the CLI and in conjur-api-ruby as the de facto
        # cert store.
        stub_const 'OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE', cert_store

        # Reset the rest_client_options defaults to avoid using expired rspec doubles.
        #
        # Conjur.configuration is a lazy-loaded singleton. There is single CLI instance
        # shared across this test suite. When Conjur.configuration is loaded for the first
        # time it assumes the defaults value for Conjur.configuration.rest_client_options
        # of:
        # {
        #  :ssl_cert_store => OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
        # }
        #
        # Notice above that each test case stubs the constant
        # OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE with a double. Without further
        # modification this means the first time the CLI is run and Conjur.configuration
        # is loaded Conjur.configuration.rest_client_options[:ssl_cert_store] it is set to
        # the double associated with the test case at that point in time. Since
        # Conjur.configuration is only loaded once, without modification, that double will
        # be retained and its usage will result in a RSpec::Mocks::ExpiredTestDoubleError.
        # To avoid this for each test case we must reset
        # Conjur.configuration.rest_client_options[:ssl_cert_store] with the double for
        # the current test case.
        Conjur.configuration.rest_client_options[:ssl_cert_store] = cert_store
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
