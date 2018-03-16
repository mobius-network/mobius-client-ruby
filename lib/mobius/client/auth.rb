class Mobius::Client::Auth
  # Raised if transaction one of transaction signatures is wrong.
  class Unauthorized < StandardError; end

  # Raised if transaction is invalid or time bounds are missing.
  class Invalid < StandardError; end

  # Raised if transaction has expired.
  class Expired < StandardError; end

  extend Dry::Initializer

  # @!method initialize(seed)
  # @param seed [String] Developers private key.
  # @!scope instance
  param :seed

  # Generates challenge transaction signed by developers private key. Minimum valid time bound is set to current time.
  # Maximum valid time bound is set to `expire_in` seconds from now.
  #
  # @param expire_in [Integer] Session expiration time (seconds from now). 0 means "never".
  # @return [String] base64-encoded transaction envelope
  def challenge(expire_in = Mobius::Client.default_challenge_expiration)
    payment = Stellar::Transaction.payment(
      account: keypair,
      destination: keypair,
      sequence: 1,
      amount: micro_xlm,
      memo: memo
    )

    payment.time_bounds = build_time_bounds(expire_in)

    payment.to_envelope(keypair).to_xdr(:base64)
  end

  # Returns time bounds for given transaction.
  #
  # @param xdr [String] base64-encoded transaction envelope.
  # @param address [String] Users public key.
  # @return [Stellar::TimeBounds] Time bounds for given transaction (`.min_time` and `.max_time`).
  # @raise [Unauthorized] if one of the signatures is invalid.
  # @raise [Invalid] if transaction is malformed or time bounds are missing.
  def time_bounds(xdr, address)
    their_keypair = Stellar::KeyPair.from_address(address)
    envelope = Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
    bounds = envelope.tx.time_bounds

    raise Unauthorized unless envelope.signed_correctly?(keypair, their_keypair)
    raise Invalid if bounds.nil?

    bounds
  end

  # Validates transaction signed by developer and user.
  #
  # @param xdr [String] base64-encoded transaction envelope.
  # @param address [String] Users public key.
  # @return [Boolean] true if transaction is valid, raises exception otherwise.
  # @raise [Unauthorized] if one of the signatures is invalid.
  # @raise [Invalid] if transaction is malformed or time bounds are missing.
  # @raise [Expired] if transaction is expired (current time outside it's time bounds).
  def validate!(xdr, address)
    bounds = time_bounds(xdr, address)
    raise Expired unless time_now_covers?(bounds)
    true
  end

  # @return [Stellar::Keypair] Stellar::Keypair object for given seed.
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  private

  def build_time_bounds(expire_in)
    Stellar::TimeBounds.new(
      min_time: Time.now.to_i,
      max_time: Time.now.to_i + expire_in.to_i || 0
    )
  end

  def micro_xlm
    Stellar::Amount.new(1).to_payment
  end

  def memo
    Stellar::Memo.new(:memo_text, "Mobius Wallet authentication")
  end

  def time_now_covers?(time_bounds)
    (time_bounds.min_time..time_bounds.max_time).cover?(Time.now.to_i)
  end
end
