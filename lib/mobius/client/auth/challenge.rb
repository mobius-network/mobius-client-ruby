class Mobius::Client::Auth::Challenge
  extend Dry::Initializer

  # @!method initialize(seed)
  # @param seed [String] Developers private key
  # @!scope instance
  param :seed

  # Generates challenge transaction signed by developers private key. Minimum valid time bound is set to current time.
  # Maximum valid time bound is set to `expire_in` seconds from now.
  #
  # @param expire_in [Integer] Session expiration time (seconds from now). 0 means "never".
  # @return [String] base64-encoded transaction envelope
  def call(expire_in = Mobius::Client.challenge_expires_in)
    payment = Stellar::Transaction.payment(
      account: Stellar::KeyPair.random,
      destination: keypair,
      sequence: random_sequence,
      amount: micro_xlm,
      memo: memo
    )

    payment.time_bounds = build_time_bounds(expire_in)

    payment.to_envelope(keypair).to_xdr(:base64)
  end

  class << self
    # Shortcut to challenge generation method.
    #
    # @param seed [String] Developers private key
    # @return [String] base64-encoded transaction envelope
    def call(*args)
      new(*args).call
    end
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
