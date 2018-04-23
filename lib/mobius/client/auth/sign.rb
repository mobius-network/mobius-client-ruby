# Signs challenge transaction on user's side.
class Mobius::Client::Auth::Sign
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(seed, xdr)
  # @param seed [String] Users private key
  # @param xdr [String] Challenge transaction xdr
  # @param address [String] Developers public key
  # @!scope instance
  param :seed
  param :xdr
  param :address

  # @!method call(seed, xdr, address)
  # Adds signature to given transaction.
  # @param seed [String] Users private key
  # @param xdr [String] Challenge transaction xdr
  # @param address [String] Developers public key
  # @return [String] base64-encoded transaction envelope
  # @!scope class

  # Adds signature to given transaction.
  #
  # @return [String] base64-encoded transaction envelope
  def call
    validate!
    envelope.dup.tap { |e| e.signatures << e.tx.sign_decorated(keypair) }.to_xdr(:base64)
  end

  private

  # @return [Stellar::Keypair] Stellar::Keypair object for given seed.
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  # @return [Stellar::Keypair] Stellar::Keypair object for given address.
  def developer_keypair
    @developer_keypair ||= Stellar::KeyPair.from_address(address)
  end

  # @return [Stellar::TransactionEnvelope] Stellar::TransactionEnvelope for given challenge.
  def envelope
    @envelope ||= Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
  end

  def validate!
    raise Mobius::Client::Error::Unauthorized unless envelope.signed_correctly?(developer_keypair)
  end
end
