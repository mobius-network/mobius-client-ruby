# TODO: Use newcomes
class Mobius::Client::App
  extend Dry::Initializer

  # @!method initialize(seed)
  # @param seed [String] Developers private key.
  # @param address [String] Users public key.
  # @!scope instance
  param :seed
  param :address

  # Checks if developer is authorized to use an application.
  # @return [Bool] Authorization status.
  def authorized?
    user_account.authorized?(app_keypair)
  end

  # Returns user balance.
  # @return [Float] User balance.
  def balance
    validate!
    balance_object["balance"].to_f
  end

  # Returns application balance.
  # @return [Float] Application balance.
  def app_balance
    app_balance_object["balance"].to_f
  end

  # Makes payment.
  # @param amount [Float] Payment amount.
  # @param target_address [String] Optional: third party receiver address.
  def pay(amount, target_address: nil)
    current_balance = balance
    raise Mobius::Client::Error::InsufficientFunds if current_balance < amount.to_f
    envelope_base64 = payment_tx(amount, target_address).to_envelope(app_keypair).to_xdr(:base64)
    post_tx(envelope_base64).tap do
      [app_account, user_account].each(&:reload!)
    end
  end

  # Sends money from application account to third party.
  # @param amount [Float] Payment amount.
  # @param address [String] Target address.
  def transfer(amount, address)
    current_balance = app_balance
    raise Mobius::Client::Error::InsufficientFunds if current_balance < amount.to_f
    envelope_base64 = transfer_tx(amount, address).to_envelope(app_keypair).to_xdr(:base64)
    post_tx(envelope_base64).tap do
      [app_account, user_account].each(&:reload!)
    end
  end

  private

  def post_tx(tx)
    Mobius::Client.horizon_client.horizon.transactions._post(tx: tx)
  end

  def payment_tx(amount, target_address)
    Stellar::Transaction.for_account(
      account: user_keypair,
      sequence: user_account.next_sequence_value,
      fee: target_address.nil? ? FEE : FEE * 2
    ).tap do |t|
      t.operations << payment_op(amount)
      t.operations << third_party_payment_op(target_address, amount) if target_address
    end
  end

  def payment_op(amount)
    Stellar::Operation.payment(
      destination: app_keypair,
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def third_party_payment_op(target_address, amount)
    Stellar::Operation.payment(
      source_account: app_keypair,
      destination: Mobius::Client.to_keypair(target_address),
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def transfer_tx(amount, address)
    Stellar::Transaction.payment(
      account: user_keypair,
      sequence: user_account.next_sequence_value,
      destination: Mobius::Client.to_keypair(address),
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def validate!
    raise Mobius::Client::Error::AuthorisationMissing unless authorized?
    raise Mobius::Client::Error::TrustlineMissing if balance_object.nil?
  end

  def limit
    balance_object["limit"].to_f
  end

  def balance_object
    find_balance(user_account.info.balances)
  end

  def app_balance_object
    find_balance(app_account.info.balances)
  end

  def find_balance(balances)
    balances.find do |s|
      s["asset_code"] == Mobius::Client.asset_code && s["asset_issuer"] == Mobius::Client.asset_issuer
    end
  end

  def app_keypair
    @app_keypair ||= Mobius::Client.to_keypair(seed)
  end

  def user_keypair
    @user_keypair ||= Mobius::Client.to_keypair(address)
  end

  def app_account
    @app_account ||= Mobius::Client::Blockchain::Account.new(app_keypair)
  end

  def user_account
    @user_account ||= Mobius::Client::Blockchain::Account.new(user_keypair)
  end

  FEE = 100
end
