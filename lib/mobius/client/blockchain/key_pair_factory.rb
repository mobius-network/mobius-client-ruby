module Mobius::Client::Blockchain::KeyPairFactory
  class << self
    # rubocop:disable Metrics/MethodLength
    def produce(subject)
      case subject
      when String
        from_string(subject)
      when Stellar::Account
        subject.keypair
      when Stellar::PublicKey
        from_public_key(subject)
      when Stellar::SignerKey
        from_secret_key(subject)
      when Stellar::KeyPair
        subject
      else
        raise Mobius::Client::Error::UnknownKeyPairType, "Unknown KeyPair type: #{subject.class.name}"
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def from_string(subject)
      subject[0] == "S" ? Stellar::KeyPair.from_seed(subject) : Stellar::KeyPair.from_address(subject)
    end

    def from_public_key(subject)
      Stellar::KeyPair.from_public_key(subject.value)
    end

    def from_secret_key(subject)
      Stellar::KeyPair.from_raw_seed(subject.value)
    end
  end
end
