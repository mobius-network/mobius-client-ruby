RSpec.describe Mobius::Client::Blockchain::AddCosigner do
  subject(:add_cosigner) { described_class.new(keypair, cosigner_keypair) }

  let(:cosigner_keypair) { Stellar::KeyPair.random }

  context "when account is missing" do
    let(:keypair) { Stellar::KeyPair.from_seed("SDSZGWR22BNISMXUXBYOKRWVAFYIQA4SX2MZLAF6MB5OHOPGES7GBPCV") }

    it do
      VCR.use_cassette("account/missing") do
        expect { add_cosigner.call }.to raise_error(Mobius::Client::Error::AccountMissing)
      end
    end
  end

  context "when account is present" do
    let(:keypair) { Stellar::KeyPair.from_seed("SBSMP2XMYUIKSE5LZAYZLXSZ3HSCCBKD37H6NXGL22GP7ZA4PEIZBVFL") }

    it do
      VCR.use_cassette("account/missing_cosigner_on_create") do
        expect(add_cosigner.call).not_to be_nil
      end
    end
  end
end
