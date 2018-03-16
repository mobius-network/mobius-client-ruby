class Mobius::Client::Auth
  class Unauthorized < StandardError; end
  class InvalidTimeBounds < StandardError; end
  class Expired < StandardError; end

  extend Dry::Initializer

  param :seed

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

  def time_bounds(xdr, address)
    their_keypair = Stellar::KeyPair.from_address(address)
    envelope = Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
    bounds = envelope.tx.time_bounds

    raise Unauthorized unless envelope.signed_correctly?(keypair, their_keypair)
    raise InvalidTimeBounds if bounds.nil?

    bounds
  end

  def validate!(xdr, address)
    bounds = time_bounds(xdr, address)
    raise Expired unless time_now_covers?(bounds)
    true
  end

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
