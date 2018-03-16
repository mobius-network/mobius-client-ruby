class Mobius::Client::Auth
  class Unauthorized < StandardError; end

  extend Dry::Initializer

  param :seed

  def challenge
    payment = Stellar::Transaction.payment(
      account: keypair,
      destination: keypair,
      sequence: 1,
      amount: Stellar::Amount.new(1).to_payment,
      memo: Stellar::Memo.new(:memo_id, Time.now.to_i)
    )

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
end
