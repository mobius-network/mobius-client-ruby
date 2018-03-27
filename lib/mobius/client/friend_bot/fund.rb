# rubocop:disable Metrics/ClassLength
class Mobius::Client::FriendBot::Fund < ServiceObject
  param :addr
  param :amount, proc(&:to_i), default: -> { MIN_AMOUNT }

  MIN_AMOUNT = 1000
  MAX_AMOUNT = 5000
  LIMIT = 922337203685 # ruby-stellar-base needs to be fixed, it does not accept unlimited now

  class Error < StandardError; end

  class WrongAddress < Error
    def message
      "Invalid target address/seed".freeze
    end
  end

  class WrongAmount < Error
    def message
      "Amount must be between #{MIN_AMOUNT} and #{MAX_AMOUNT}".freeze
    end
  end

  class TrustlineMissing < Error
    def message
      config = Mobius::Config.friendbot
      tl = "#{config.asset_code}/#{config.asset_issuer}"
      "Trust line missing for #{tl} on target account, pass account private key to create".freeze
    end
  end

  def call
    validate!

    create_account if account_missing?

    if trustline_missing?
      raise TrustlineMissing unless seed_given?
      create_trustline
    end

    fund
  end

  private

  def validate!
    raise WrongAddress if addr.blank?
    raise WrongAmount unless valid_amount?
    raise TrustlineMissing if account_missing? && !seed_given?
  end

  def valid_amount?
    (MIN_AMOUNT..MAX_AMOUNT).cover?(amount)
  end

  def seed_given?
    addr[0] == "S"
  end

  def account
    seed_given? ? Stellar::Account.from_seed(addr) : Stellar::Account.from_address(addr)
  rescue TypeError, ArgumentError
    raise WrongAddress
  end

  def friendbot_account
    Stellar::Account.from_address(friendbot_keypair.address)
  end

  def account_info
    @account_info ||= client.account_info(account)
  end

  def friendbot_account_info
    @friendbot_account_info ||= client.account_info(friendbot_account)
  end

  def client
    @client ||= Mobius::Config.stellar_testnet_client
  end

  def account_missing?
    account_info
    false
  rescue Faraday::ResourceNotFound
    true
  end

  def trustline_missing?
    balance.blank?
  end

  def balance
    @balance ||= account_info.balances.find do |s|
      s["asset_code"] == config.asset_code && s["asset_issuer"] == config.asset_issuer
    end
  end

  def create_trustline
    Stellar.on_network(Stellar::Networks::TESTNET) do
      client.horizon.transactions._post(tx: change_trust_tx.to_envelope(account.keypair).to_xdr(:base64))
    end
  end

  def change_trust_tx
    Stellar::Transaction.change_trust(
      account: account.keypair,
      line: [:alphanum4, config.asset_code, asset_issuer_keypair],
      limit: LIMIT,
      sequence: account_info.sequence.to_i + 1
    )
  end

  def create_account
    client.horizon.friendbot._post(addr: account.address)
  end

  def config
    Mobius::Config.friendbot
  end

  def asset_issuer_keypair
    @asset_issuer_keypair ||= Stellar::KeyPair.from_address(config.asset_issuer)
  end

  def friendbot_keypair
    @friendbot_keypair ||= Stellar::KeyPair.from_seed(config["key"])
  end

  def fund
    Stellar.on_network(Stellar::Networks::TESTNET) do
      client.horizon.transactions._post(
        tx: fund_tx.to_envelope(friendbot_keypair).to_xdr(:base64)
      )
    end
  end

  def fund_tx
    Stellar::Transaction.payment(
      account: friendbot_keypair,
      destination: account.keypair,
      asset: asset,
      amount: amount_to_payment,
      sequence: friendbot_account_info.sequence.to_i + 1
    )
  end

  def asset
    Stellar::Asset.alphanum4(config.asset_code, asset_issuer_keypair)
  end

  def amount_to_payment
    Stellar::Amount.new(amount, asset).to_payment
  end
end
# rubocop:enable Metrics/ClassLength
