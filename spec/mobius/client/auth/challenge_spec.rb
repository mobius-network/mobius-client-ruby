RSpec.describe Mobius::Client::Auth::Challenge do
  subject(:envelope) { Stellar::TransactionEnvelope.from_xdr(challenge, "base64") }

  let(:seed) { Stellar::KeyPair.random.seed }
  let(:keypair) { Stellar::KeyPair.from_seed(seed) }
  let(:challenge) { described_class.call(seed) }

  it "signs challenge correctly by us" do
    expect(envelope.signed_correctly?(keypair)).to eq(true)
  end

  it "contains memo" do
    expect(envelope.tx.memo.value).to match(/Mobius/)
  end

  it "contains time bounds" do
    expect(envelope.tx.time_bounds).not_to be_nil
  end

  it "contains minimum bound" do
    Timecop.freeze { expect(envelope.tx.time_bounds.min_time).to eq(Time.now.to_i) }
  end
end
