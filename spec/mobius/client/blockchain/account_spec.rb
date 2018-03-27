RSpec.describe Mobius::Client::Blockchain::Account do
  subject(:account) { described_class.new(keypair) }

  let(:keypair) { Stellar::KeyPair.random }

  it "returns authorized status" do
    account.authorized?
  end
end
