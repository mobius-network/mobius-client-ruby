# Transforms given value into Stellar::Keypair object.
module Mobius::Client::Blockchain::KeyPairFactory
  class << self
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    # Generates Stellar::Keypair from subject, use Stellar::Client.to_keypair as shortcut.
    # @param subject [String||Stellar::Account||Stellar::PublicKey||Stellar::SignerKey||Stellar::Keypair] subject.
    # @return [Stellar::Keypair] Stellar::Keypair instance.
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
    rescue ArgumentError => e
      raise Mobius::Client::Error::UnknownKeyPairType, "Unknown KeyPair type: #{e.message}"
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

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
