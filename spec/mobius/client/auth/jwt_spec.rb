RSpec.describe Mobius::Client::Auth::Jwt do
  subject(:jwt) { described_class.new("test") }

  let(:user_seed) { Stellar::KeyPair.random.seed }
  let(:developer_seed) { Stellar::KeyPair.random.seed }
  let(:user_keypair) { Stellar::KeyPair.from_seed(user_seed) }
  let(:developer_keypair) { Stellar::KeyPair.from_seed(developer_seed) }
  let(:challenge) { Mobius::Client::Auth::Challenge.call(developer_seed) }
  let(:signed_challenge) { Mobius::Client::Auth::Sign.call(user_seed, challenge, developer_keypair.address) }
  let(:jwt_secret) { "test" }
  let(:token) { Mobius::Client::Auth::Token.new(developer_seed, signed_challenge, user_keypair.address) }

  it "returns jwt token" do
    expect(jwt.generate(token)).not_to be_nil
  end

  context "when #decode! is called" do
    it "decodes token" do
      expect(jwt.decode!(jwt.generate(token))).to be_kind_of(OpenStruct)
    end
  end
end
