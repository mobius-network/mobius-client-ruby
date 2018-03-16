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

  describe "#valid?" do
    let(:valid) { described_class.new(seed).valid?(xdr, their_keypair.address) }
    let(:xdr) { envelope.dup.tap { |e| e.signatures << e.tx.sign_decorated(their_keypair) }.to_xdr(:base64) }
    let(:future) { Time.new(Time.now.to_i + Mobius::Client.default_challenge_expiration * 5) }

    it "returns min time" do
      Timecop.freeze(Time.now) { expect(valid).to eq(true) }
    end

    it "returns max time, 0 by default" do
      xdr
      Timecop.freeze(future) { expect { valid }.to raise_error(Mobius::Client::Auth::Expired) }
    end
  end
end
