class Mobius::Client::Auth::Sign
  extend Dry::Initializer

  param :seed
  param :xdr

  # Adds signature to given transaction.
  #
  # @return [String] base64-encoded transaction envelope
  def call
    envelope.dup.tap { |e| e.signatures << e.tx.sign_decorated(their_keypair) }.to_xdr(:base64)
  end

  class << self
    def call(*args)
      new(*args).call
    end
  end

  private

  # @return [Stellar::Keypair] Stellar::Keypair object for given seed.
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  # @return [Stellar::TransactionEnvelope] Stellar::TransactionEnvelope for given challenge.
  def envelope
    @envelope ||= Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
  end
end
