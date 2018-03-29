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
    user_account.account.signers.find { |s| s["public_key"] == keypair.address }.nil? && limit.positive?
  end

  # Returns user balance.
  # @return [Float] Application balance.
  def balance
    validate!
    balance_object["balance"].to_f
  end

  # Makes payment.
  # @param amount [Float] Payment amount.
  def use(amount)
    current_balance = balance
    raise Mobius::Client::Error::InsufficientFunds if current_balance < amount.to_f
    envelope_base64 = payment_tx(amount).to_envelope(keypair).to_xdr(:base64)
    Mobius::Client.horizon_client.horizon.transactions._post(tx: envelope_base64)
  end

  private

  def payment_tx(amount)
    Stellar::Transaction.payment(
      account: user_keypair,
      destination: app_keypair,
      sequence: user_account.next_sequence_value,
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def validate!
    raise Mobius::Client::Error::Unauthorized unless authorized?
    raise Mobius::Client::Error::TrustlineMissing if balance_object.nil?
  end

  def limit
    balance_object["limit"].to_f
  end

  def balance_object
    user_account.account.balances.find do |s|
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
end
