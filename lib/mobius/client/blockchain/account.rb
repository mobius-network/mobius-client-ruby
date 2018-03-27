class Mobius::Client::Blockchain::Account
  extend Dry::Initializer

  param :keypair

  def authorized?(to_keypair)
    account_info.signers.find { |s| s["public_key"] == to_keypair.address }.nil?
  end

  def balance(asset = Mobius.Client.stellar_asset)
    balance = account_info.balances.find { |s| s["asset_code"] == asset.code && s["asset_issuer"] == asset.issuer }
    raise Mobius::Error::TrustlineMissing if balance.nil?
    balance.dig("balance").to_f
  end

  def account
    @account ||= Stellar::Account.from_seed(keypair.seed)
  end

  def account_info
    @account_info ||= Mobius::Client.horizon_client.account_info(stellar_account)
  end
end
