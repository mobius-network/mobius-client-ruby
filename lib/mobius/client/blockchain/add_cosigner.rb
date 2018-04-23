# Adds account as cosigner to other account.
class Mobius::Client::Blockchain::AddCosigner
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(keypair, cosigner, weight)
  # @param keypair [Stellar::Keypair] Account keypair
  # @param cosigner_keypair [Stellar::Keypair] Cosigner account keypair
  # @param weight [Integer] Cosigner weight, default: 1
  # @!scope instance
  param :keypair
  param :cosigner_keypair
  param :weight, default: -> { 1 }

  # @!method call(keypair, cosigner, weight)
  # Executes an operation.
  # @param keypair [Stellar::Keypair] Account keypair
  # @param cosigner_keypair [Stellar::Keypair] Cosigner account keypair
  # @param weight [Integer] Cosigner weight, default: 1
  # @!scope class

  # Executes an operation
  def call
    client.horizon.transactions._post(
      tx: tx.to_envelope(keypair).to_xdr(:base64)
    )
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end

  private

  # TODO: weight must be params
  def tx
    Stellar::Transaction.set_options(
      account: keypair,
      sequence: account.next_sequence_value,
      signer: signer,
      master_weight: 10,
      highThreshold: 10,
      medThreshold: 1,
      lowThreshold: 1
    )
  end

  def signer
    Stellar::Signer.new(
      key: Stellar::SignerKey.new(:signer_key_type_ed25519, cosigner_keypair.raw_public_key), weight: weight
    )
  end

  def account
    @account ||= Mobius::Client::Blockchain::Account.new(keypair)
  end

  def client
    @client ||= Mobius::Client.horizon_client
  end
end
