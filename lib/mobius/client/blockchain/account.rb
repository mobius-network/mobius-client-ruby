class Mobius::Client::Blockchain::Account
  extend Dry::Initializer

  param :keypair

  def trustline_exists?(asset = Mobius::Client.stellar_asset)
    balance = find_balance(asset)
    (balance && !balance.dig("limit").to_f.zero?) || false
  end

  def balance(asset = Mobius::Client.stellar_asset)
    balance = find_balance(asset)
    balance && balance.dig("balance").to_f
  end

  def authorized?(to_keypair)
    !find_signer(to_keypair.address).nil?
  end

  def account
    @account ||= Stellar::Account.from_seed(keypair.seed)
  end

  def info
    @info ||= Mobius::Client.horizon_client.account_info(account)
  end

  def next_sequence_value
    info.sequence.to_i + 1
  end

  private

  def find_balance(asset)
    info.balances.find { |balance| balance_matches?(asset, balance) }
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end

  def balance_matches?(asset, balance)
    if [:native, Stellar::Asset.native].include?(asset)
      balance["asset_type"] == "native"
    else
      code = balance["asset_code"]
      issuer = balance["asset_issuer"]
      asset_issuer_address = Mobius::Client.to_keypair(asset.issuer).address
      code == asset.code && issuer == asset_issuer_address
    end
  end

  # TODO: Think of adding weight check here
  def find_signer(address)
    info.signers.find { |s| s["public_key"] == address }
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end
end
