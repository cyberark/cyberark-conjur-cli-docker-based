shared_context "with fake endpoints and test config" do
  let(:authn_host) { 'https://authn.example.com' }
  let(:authz_host) { 'https://authz.example.com' }
  let(:core_host) { 'https://core.example.com' }
  before do
    allow(Conjur::Authn::API).to receive(:host) { authn_host }
    allow(Conjur::Authz::API).to receive(:host) { authz_host }
    allow(Conjur::Core::API).to receive(:host) { core_host }

    ENV['GLI_DEBUG'] = 'true'
  end
end

shared_context "with mock authn" do
  include_context "with fake endpoints and test config"
  let(:netrcfile) { Tempfile.new 'authtest' }
  let(:netrc) { Netrc.read(netrcfile.path) }
  let(:account) { 'the-account' }
  before do
    allow(Conjur::Core::API).to receive(:conjur_account) { account }
    allow(Conjur::Authn).to receive_messages(netrc: netrc, host: authn_host)
    Conjur::Config.merge 'account' => account
  end
end

shared_context "when logged in", logged_in: true do
  include_context "with mock authn"
  let(:username) { 'dknuth' }
  let(:api_key) { 'sekrit' }
  let(:api) { Conjur::API.new_from_key(username, api_key) }
  before do
    allow(api).to receive(:credentials) { {} }
    netrc[authn_host] = [username, api_key]
    allow(Conjur::Command).to receive_messages api: api
  end
end

shared_context "when not logged in", logged_in: false do
  include_context "with mock authn"
end
