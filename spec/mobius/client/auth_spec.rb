RSpec.describe Mobius::Client::Auth do
  let(:seed) { Stellar::KeyPair.random.seed }
  let(:their_seed) { Stellar::KeyPair.random.seed }
  let(:keypair) { described_class.new(seed).keypair }
  let(:their_keypair) { Stellar::KeyPair.from_seed(their_seed) }
  let(:challenge) { described_class.new(seed).challenge }
  let(:envelope) { Stellar::TransactionEnvelope.from_xdr(challenge, "base64") }

  describe "#challenge" do
    it "signs challenge correctly" do
      expect(envelope.signed_correctly?(keypair)).to eq(true)
    end

    it "contains timestamp" do
      expect(envelope.tx.memo.value).not_to be_nil
    end
  end

  describe "#timestamp" do
    let(:timestamp) { described_class.new(seed).timestamp(xdr, their_keypair.address) }
    let(:xdr) { envelope.dup.tap { |e| e.signatures << e.tx.sign_decorated(their_keypair) }.to_xdr(:base64) }

    it "returns value" do
      expect(timestamp).not_to eq(nil)
    end
  end
end
