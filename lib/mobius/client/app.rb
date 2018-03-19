class Mobius::Client::App
  extend Dry::Initializer

  class Unauthorized < StandardError; end
  class TrustlineMissing < StandardError; end
  class InsufficientFunds < StandardError; end

  param :seed
  param :address

  def authorized?
    on_network do
      !info(user_account).signers.find { |s| s["public_key"] == keypair.address }.nil? && limit.positive?
    end
  end

  def balance
    on_network do
      validate!
      balance_object["balance"].to_f
    end
  end

  def use(amount)
    on_network do
      current_balance = balance
      raise InsufficientFunds if current_balance < amount.to_f
      envelope_base64 = payment_tx(amount).to_envelope(keypair).to_xdr(:base64)
      Mobius::Client.horizon_client.horizon.transactions._post(tx: envelope_base64)
    end
  end

  # private

  def payment_tx(amount)
    Stellar::Transaction.payment(
      account: user_account.keypair,
      destination: keypair,
      sequence: info(user_account).sequence.to_i + 1,
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def validate!
    raise Unauthorized unless authorized?
    raise TrustlineMissing if balance_object.nil?
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
