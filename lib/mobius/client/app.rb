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
    on_network do
      !info(user_account).signers.find { |s| s["public_key"] == keypair.address }.nil? && limit.positive?
    end
  end

  # Returns user balance.
  # @return [Float] Application balance.
  def balance
    on_network do
      validate!
      balance_object["balance"].to_f
    end
  end

  # Makes payment.
  # @param amount [Float] Payment amount.
  def use(amount)
    on_network do
      current_balance = balance
      raise Mobius::Client::Error::InsufficientFunds if current_balance < amount.to_f
      envelope_base64 = payment_tx(amount).to_envelope(keypair).to_xdr(:base64)
      Mobius::Client.horizon_client.horizon.transactions._post(tx: envelope_base64)
    end
  end

  private

  def payment_tx(amount)
    Stellar::Transaction.payment(
      account: user_account.keypair,
      destination: keypair,
      sequence: info(user_account).sequence.to_i + 1,
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
    info(user_account).balances.find do |s|
      s["asset_code"] == Mobius::Client.asset_code && s["asset_issuer"] == Mobius::Client.asset_issuer
    end
  end

  def on_network
    Stellar.on_network(Mobius::Client.network == :test ? ::Stellar::Networks::TESTNET : ::Stellar::Networks::PUBLIC) do
      yield if block_given?
    end
  end

  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  def user_account
    @user_account ||= Stellar::Account.from_address(address)
  end

  def developer_account
    @developer_account ||= Stellar::Account.from_seed(seed)
  end

  def info(account)
    Mobius::Client.horizon_client.account_info(account)
  end
end
