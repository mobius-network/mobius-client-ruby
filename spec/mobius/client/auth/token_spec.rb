RSpec.describe Mobius::Client::Auth::Token do
  subject(:token) { described_class.new(developer_seed, signed_challenge, user_keypair.address) }

  let(:user_seed) { Stellar::KeyPair.random.seed }
  let(:developer_seed) { Stellar::KeyPair.random.seed }
  let(:user_keypair) { Stellar::KeyPair.from_seed(user_seed) }
  let(:developer_keypair) { Stellar::KeyPair.from_seed(developer_seed) }
  let(:challenge) { Mobius::Client::Auth::Challenge.call(developer_seed) }
  let(:signed_challenge) { Mobius::Client::Auth::Sign.call(user_seed, challenge, developer_keypair.address) }
  let(:future) { Time.at(Time.now.to_i + Mobius::Client.challenge_expires_in * 5) }

  it "#validate! returns true if current time is within bounds" do
    Timecop.freeze(Time.now) { expect(token.validate!).to eq(true) }
  end

  it "#validate! raises if current time is outside bounds" do
    challenge # Generate challenge while we're in the past
    Timecop.freeze(future) { expect { token.validate! }.to raise_error(Mobius::Client::Auth::Token::Expired) }
  end

  it "returns transaction hash" do
    expect(token.hash).not_to be_empty
  end
end
