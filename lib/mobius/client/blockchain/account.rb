# Service class used to interact with account on Stellar network.
class Mobius::Client::Blockchain::Account
  extend Dry::Initializer

  # @!method initialize(keypair)
  # @param keypair [Stellar::Keypair] account keypair
  # @!scope instance
  param :keypair, Mobius::Client.method(:to_keypair)

  # Returns true if trustline exists for given asset and limit is positive.
  # @param asset [Stellar::Asset] Stellar asset to check or :native
  # @return [Boolean] true if trustline exists
  def trustline_exists?(asset = Mobius::Client.stellar_asset)
    balance = find_balance(asset)
    (balance && !balance.dig("limit").to_d.zero?) || false
  end

  # Returns balance for given asset
  # @param asset [Stellar::Asset] Stellar asset to check or :native
  # @return [Float] Balance value.
  def balance(asset = Mobius::Client.stellar_asset)
    balance = find_balance(asset)
    balance = balance&.dig("balance")
    return balance.to_d if balance
  end

  # Returns true if given keypair is added as cosigner to current account.
  # @param to_keypair [Stellar::Keypair] Keypair in question
  # @return [Boolean] true if cosigner added
  # TODO: Add weight check/return
  def authorized?(to_keypair)
    !find_signer(to_keypair.address).nil?
  end

  # Returns Stellar::Account instance for given keypair.
  # @return [Stellar::Account] instance
  def account
    @account ||=
      if keypair.sign?
        Stellar::Account.from_seed(keypair.seed)
      else
        Stellar::Account.from_address(keypair.address)
      end
  end

  # Requests and caches Stellar::Account information from network.
  # @return [Stellar::Account] account information.
  def info
    @info ||= Mobius::Client.horizon_client.account_info(account)
  end

  # Invalidates account information cache.
  def reload!
    @info = nil
  end

  # Invalidates cache and returns next sequence value for given account.
  # @return [Integer] sequence value.
  def next_sequence_value
    reload!
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
