RSpec.describe Mobius::Client::Blockchain::CreateTrustline do
  subject(:create_trustline) { described_class.new(keypair) }

  context "when account is missing" do
    let(:keypair) { Stellar::KeyPair.from_seed("SDSZGWR22BNISMXUXBYOKRWVAFYIQA4SX2MZLAF6MB5OHOPGES7GBPCV") }

    it do
      VCR.use_cassette("account/missing") do
        expect { create_trustline.call }.to raise_error(Mobius::Client::Error::AccountMissing)
      end
    end
  end

  context "when account is present" do
    let(:keypair) { Stellar::KeyPair.from_seed("SBK5TEYJ4XKBX7RC34SUEDSY4BKDUPQVJEVOLTHAIMG72Y3UOOPJKA4W") }

    it do
      VCR.use_cassette("account/missing_trustline_on_create") do
        expect(create_trustline.call).not_to be_nil
      end
    end
  end
end
