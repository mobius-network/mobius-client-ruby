RSpec.describe Mobius::Client::Auth::Token do
  subject(:token) { described_class.new(seed, signed_challenge, their_keypair.address) }

  let(:seed) { Stellar::KeyPair.random.seed }
  let(:their_seed) { Stellar::KeyPair.random.seed }
  let(:keypair) { Stellar::KeyPair.from_seed(seed) }
  let(:their_keypair) { Stellar::KeyPair.from_seed(their_seed) }
  let(:challenge) { Mobius::Client::Auth::Challenge.call(seed) }
  let(:signed_challenge) { Mobius::Client::Auth::Sign.call(their_seed, challenge) }

  let(:future) { Time.at(Time.now.to_i + Mobius::Client.challenge_expires_in * 5) }

  it "returns min time" do
    Timecop.freeze(Time.now) { expect(token.valid?).to eq(true) }
  end

  it "returns max time, 0 by default" do
    xdr
    Timecop.freeze(future) { expect { token.validate! }.to raise_error(Mobius::Client::Auth::Expired) }
  end
end
