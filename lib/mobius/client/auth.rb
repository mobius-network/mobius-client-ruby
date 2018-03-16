class Mobius::Client::Auth
  class Unauthorized < StandardError; end

  extend Dry::Initializer

  param :seed

  def challenge(expire = 0)
    payment = Stellar::Transaction.payment(
      account: keypair,
      destination: keypair,
      sequence: 1,
      amount: micro_xlm,
      memo: memo
    )

    payment.time_bounds = time_bounds(expire)

    payment.to_envelope(keypair).to_xdr(:base64)
  end

  def timestamp(xdr, address)
    their_keypair = Stellar::KeyPair.from_address(address)
    envelope = Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
    raise Unauthorized unless envelope.signed_correctly?(keypair, their_keypair)
    envelope.tx.memo.value
  end

  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  private

  def time_bounds(expire)
    Stellar::TimeBounds.new(
      min_time: Time.now.to_i,
      max_time: expire || 0
    )
  end

  def micro_xlm
    Stellar::Amount.new(1).to_payment
  end

  def memo
    Stellar::Memo.new(:memo_text, "Mobius Wallet authorization")
  end
end
