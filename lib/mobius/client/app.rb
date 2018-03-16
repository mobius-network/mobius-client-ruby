class Mobius::Client::App
  extend Dry::Initializer

  class Unauthorized < StandardError; end
  class TrustlineMissing < StandardError; end
  class InsufficientFunds < StandardError; end

  param :seed
  param :address

  def authorized?
    on_network do
      !user_account.signers.find { |s| s["public_key"] == keypair.address }.nil? && limit.positive?
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
      raise InsufficientFunds if current_balance > amount.to_f
    end
  end

  private

  def validate!
    raise Unauthorized unless authorized?
    raise TrustlineMissing if balance_object.nil?
  end

  def limit
    balance_object["limit"].to_f.positive?
  end

  def balance_object
    user_account.balances.find do |s|
      s["asset_code"] == Mobius::Client.asset_code && s["asset_issuer"] == Mobius::Client.asset_issuer
    end
  end

  def on_network
    Stellar.on_network(Mobius::Client.network == :test ? ::Stellar::Networks::TESTNET : ::Stellar::Networks::PUBLIC) do
      yield if block_given?
    end
  end

  def account
    @account ||= Stellar::Account.from_address(address)
  end

  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  def user_account
    @user_account ||= client.account_info(account)
  end
end
