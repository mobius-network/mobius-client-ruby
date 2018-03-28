class Mobius::Client::Blockchain::AddCosigner
  param :keypair

  def call
    client.horizon.transactions._post(tx: tx.to_envelope(keypair).to_xdr(:base64))
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end

  # TODO: DRY
  class << self
    def call(*args)
      new(*args).call
    end
  end

  private

  def tx
    # const setSignerOp = StellarSdk.Operation.setOptions({
    #   source: appKeyPair.publicKey(),
    #   signer: {
    #     ed25519PublicKey: developerPublicKey,
    #     weight: 1
    #   }
    # })
    #
    # const setWeightsOp = StellarSdk.Operation.setOptions({
    #   source: appKeyPair.publicKey(),
    #   masterWeight: 10,
    #   highThreshold: 10,
    #   medThreshold: 1,
    #   lowThreshold: 1
    # })

    Stellar::Transaction.change_trust(
      account: keypair,
      line: [:alphanum4, asset.code, Mobius::Client.to_keypair(asset.issuer)],
      limit: LIMIT,
      sequence: account.next_sequence_value
    )
  end

  def account
    @account ||= Mobius::Client::Blockchain::Account.new(keypair)
  end

  def client
    @client ||= Mobius::Client.horizon_client
  end
end
