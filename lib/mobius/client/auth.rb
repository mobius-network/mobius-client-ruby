class Mobius::Client::Auth
  class Unauthorized < StandardError;

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

  def timestamp(xdr, public_key)
    their_keypair = Stellar::KeyPair.from_public_key(public_key)
    envelope = Stellar::TransactionEnvelope.from_xdr(Base64.decode64(xdr))
    raise Unauthorized unless envelope.signed_correctly?(keypair, their_keypair)
    Time.new(envelope.tx.memo.value)
  end

  private

  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end
end
