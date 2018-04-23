# Generates challenge transaction on developer's side.
class Mobius::Client::Auth::Challenge
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(seed, expire_in = Mobius::Client.challenge_expires_in)
  # @param seed [String] Developers private key
  # @param expire_in [Integer] Session expiration time (seconds from now). 0 means "never".
  # @!scope instance
  param :seed
  param :expire_in, default: -> { Mobius::Client.challenge_expires_in }

  # @!method call(seed, expire_in = Mobius::Client.challenge_expires_in)
  # Generates challenge transaction signed by developers private key. Minimum valid time bound is set to current time.
  # Maximum valid time bound is set to `expire_in` seconds from now.
  # @param seed [String] Developers private key
  # @param expire_in [Integer] Session expiration time (seconds from now). 0 means "never".
  # @return [String] base64-encoded transaction envelope
  # @!scope class

  # @return [String] base64-encoded transaction envelope
  def call
    payment = Stellar::Transaction.payment(
      source_account: keypair,
      account: Stellar::KeyPair.random,
      destination: keypair,
      sequence: random_sequence,
      amount: micro_xlm,
      memo: memo
    )

    payment.time_bounds = build_time_bounds(expire_in)

    payment.to_envelope(keypair).to_xdr(:base64)
  end

  private

  # @return [Stellar::Keypair] Stellar::Keypair object for given seed.
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  # @return [Integer] Random sequence number
  def random_sequence
    MAX_SEQ_NUMBER - SecureRandom.random_number(RANDOM_LIMITS)
  end

  # @return [Stellar::TimeBounds] Current time..expire time
  def build_time_bounds(expire_in)
    Stellar::TimeBounds.new(
      min_time: Time.now.to_i,
      max_time: Time.now.to_i + expire_in.to_i || 0
    )
  end

  # @return [Stellar::Amount] 1 XLM
  def micro_xlm
    Stellar::Amount.new(1).to_payment
  end

  # @return [Stellar::Memo] Auth transaction memo
  def memo
    Stellar::Memo.new(:memo_text, "Mobius authentication")
  end

  MAX_SEQ_NUMBER = (2**128 - 1).freeze # MAX sequence number
  RANDOM_LIMITS = 65535                # Sequence random limits
end
