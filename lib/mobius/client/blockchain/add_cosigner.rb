class Mobius::Client::Blockchain::AddCosigner
  extend Dry::Initializer

  param :keypair
  param :by_keypair

  APP_WEIGHT = 1

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
    Stellar::Transaction.set_options(
      account: keypair,
      sequence: account.next_sequence_value,
      signer: Stellar::Signer.new(key: by_keypair.signer_key, weight: APP_WEIGHT),
      master_weight: 10,
      highThreshold: 10,
      medThreshold: 1,
      lowThreshold: 1
    )
  end

  def account
    @account ||= Mobius::Client::Blockchain::Account.new(keypair)
  end

  def client
    @client ||= Mobius::Client.horizon_client
  end
end
