RSpec.describe Mobius::Client::Blockchain::Account do
  subject(:account) { described_class.new(keypair) }

  context "when account is missing" do
    let(:keypair) { Stellar::KeyPair.from_seed("SDSZGWR22BNISMXUXBYOKRWVAFYIQA4SX2MZLAF6MB5OHOPGES7GBPCV") }

    it do
      VCR.use_cassette("account/missing") do
        expect { account.balance }.to raise_error(Mobius::Client::Error::AccountMissing)
      end
    end
  end

  context "when account has not trustline & authorization" do
    let(:keypair) { Stellar::KeyPair.from_seed("SA2VTRSZPZ5FICNHEUISJVAZNE5IGKUTXFZX6ISHX3JAI4QD7LBWUUIK") }
    let(:their_keypair) { Stellar::KeyPair.random }

    it "#trustline_exists? should eq false" do
      VCR.use_cassette("account/missing_trustline") do
        expect(account.trustline_exists?).to eq(false)
      end
    end

    it "#balance should eq nil" do
      VCR.use_cassette("account/missing_trustline") do
        expect(account.balance).to be_nil
      end
    end

    it "#authorized? should eq false" do
      VCR.use_cassette("account/missing_cosigner") do
        expect(account.authorized?(their_keypair)).to eq(false)
      end
    end
  end

  context "when account has trustline & authorization" do
    let(:keypair) { Stellar::KeyPair.from_seed("SAAR4WYBEMS3HWZROEGJDDSMINYOK6PLSDX5AYEPO5AIVXWRFY2M6SBK") }
    let(:their_keypair) { Stellar::KeyPair.from_address("GAZDIAPACN6EMNHFNEDUVFTTGL45DVZJVXEGJDNKTVGMHI5YN5LXLNR4") }

    it "#trustline_exists? should eq true" do
      VCR.use_cassette("account/trustline_exists") do
        expect(account.trustline_exists?).to eq(true)
      end
    end

    it "#balance should eq 10000" do
      VCR.use_cassette("account/trustline_exists") do
        expect(account.balance).to eq(1000)
      end
    end

    it "#authorized? should eq true" do
      VCR.use_cassette("account/cosigner_exists") do
        expect(account.authorized?(their_keypair)).to eq(true)
      end
    end
  end
end
