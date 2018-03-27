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

  # TODO: Handle native balance here, Stellar::Asset.native has incompatible interface.
  def find_balance(asset)
    info.balances.find do |s|
      s["asset_code"] == asset.code && s["asset_issuer"] == Mobius::Client.to_key_pair(asset.issuer).address
    end
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end

  # TODO: Think of adding weight check here
  def find_signer(address)
    info.signers.find { |s| s["public_key"] == address }
  rescue Faraday::ResourceNotFound
    raise Mobius::Client::Error::AccountMissing
  end
end
