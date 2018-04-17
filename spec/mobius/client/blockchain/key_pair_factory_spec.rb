RSpec.describe Mobius::Client::Blockchain::KeyPairFactory do
  [
    "GBXPV52ZADY6W7U63QA3Z3XADIJGW7OOEDD4V5OVQQZKLH3FSAWUTJZR",
    "SDIR76RUEQBFC6FNQVJUYIRLMLEKXF7A5V2TIQYZBOJM34L4X6NRK34W",
    Stellar::Account.from_seed("SDIR76RUEQBFC6FNQVJUYIRLMLEKXF7A5V2TIQYZBOJM34L4X6NRK34W"),
    Stellar::KeyPair.random.public_key,
    Stellar::KeyPair.random.signer_key,
    Stellar::KeyPair.random
  ].each do |subject|
    it "Converts from #{subject.class.name} to Stellar::KeyPair" do
      expect(described_class.produce(subject)).to be_kind_of(Stellar::KeyPair)
    end
  end

  it "raises if subject has errors" do
    expect { described_class.produce("ABCD") }.to raise_error(Mobius::Client::Error::UnknownKeyPairType)
  end

  it "raises if subject is invalid" do
    expect { described_class.produce(3) }.to raise_error(Mobius::Client::Error::UnknownKeyPairType)
  end
end
