class Mobius::Client::Blockchain::CreateTrustline
  extend Dry::Initializer

  # ruby-stellar-base needs to be fixed, it does not accept unlimited now
  LIMIT = 922337203685

  param :keypair
  param :asset, default: -> { Mobius::Client.stellar_asset }

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
