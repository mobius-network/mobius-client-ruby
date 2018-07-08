# Adds account as cosigner to other account.
class Mobius::Client::Blockchain::AddCosigner
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  # @!method initialize(keypair, cosigner, cosigner_weight:, master_weight:)
  # @param keypair [Stellar::Keypair] Account keypair
  # @param cosigner_keypair [Stellar::Keypair] Cosigner account keypair
  # @param cosigner_weight [Integer] Cosigner weight, default: 1
  # @param master_weight [Integer] Master key weight, default: 10
  # @!scope instance
  param :keypair
  param :cosigner_keypair
  param :cosigner_weight, default: -> { 1 } # TODO: should be an option too
  option :master_weight, default: -> { 10 }

  # @!method call(keypair, cosigner, cosigner_weight:, master_weight:)
  # Executes an operation.
  # @param keypair [Stellar::Keypair] Account keypair
  # @param cosigner_keypair [Stellar::Keypair] Cosigner account keypair
  # @param cosigner_weight[Integer] Cosigner weight, default: 1
  # @param master_weight [Integer] Master key weight, default: 10
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

  def tx
    Stellar::Transaction.for_account(
      account: keypair,
      sequence: account.next_sequence_value
    ).tap do |txn|
      txn.operations << add_cosigner_op
      txn.operations << set_thresholds_op
      txn.fee *= txn.operations.size
    end
  end

  def add_cosigner_op
    Stellar::Operation.set_options(
      signer: cosigner,
      master_weight: master_weight
    )
  end

  def set_thresholds_op
    Stellar::Operation.set_options(
      high_threshold: master_weight,
      med_threshold: cosigner_weight,
      low_threshold: cosigner_weight
    )
  end

  def cosigner
    Stellar::Signer.new(
      key: Stellar::SignerKey.new(:signer_key_type_ed25519, cosigner_keypair.raw_public_key),
      weight: cosigner_weight
    )
  end

  def account
    @account ||= Mobius::Client::Blockchain::Account.new(keypair)
  end

  def client
    @client ||= Mobius::Client.horizon_client
  end
end
