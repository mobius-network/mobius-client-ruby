# Interface to user balance in application.
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
    user_account.balance
  end

  # Returns application balance.
  # @return [Float] Application balance.
  def app_balance
    app_account.balance
  end

  # Makes payment.
  # @param amount [Numeric, String] Payment amount.
  # @param target_address [String] Optional: third party receiver address.
  # @deprecated use {#charge} instead
  def pay(amount, target_address: nil)
    warn "[DEPRECATED] method Mobius::Client::App#pay is deprecated and will be removed, use Mobius::Client::App#charge instead"
    charge(amount, target_address)
  end

  # Charges user's wallet.
  # @param amount [Numeric, String] Payment amount.
  # @param target_address [String] Optional: third party receiver address.
  def charge(amount, target_address: nil)
    amount = cast_amount(amount)

    raise Mobius::Client::Error::InsufficientFunds if balance < amount

    submit_tx do |operations|
      operations << payment_op(amount, dest: app_keypair, src: user_keypair)
      operations << payment_op(amount, dest: target_address, src: app_keypair) if target_address
    end
  rescue Faraday::ClientError => err
    handle(err)
  end

  # Sends money from user's account to third party.
  # @param amount [Float] Payment amount.
  # @param address [String] Target address.
  def transfer(amount, address)
    amount = cast_amount(amount)
    raise Mobius::Client::Error::InsufficientFunds if app_balance < amount
    submit_tx { |operations| operations << payment_op(amount, dest: address, src: user_keypair) }
  rescue Faraday::ClientError => err
    handle(err)
  end

  # Sends money from application account to user's account or target_address, if given
  # @param amount [Float] Payment amount.
  # @param target_address [String] Optional: third party receiver address.
  def payout(amount, target_address: user_keypair.address)
    amount = cast_amount(amount)
    raise Mobius::Client::Error::InsufficientFunds if app_balance < amount
    submit_tx do |operations|
      operations << payment_op(amount, dest: target_address, src: app_keypair)
    end
  rescue Faraday::ClientError => err
    handle(err)
  end

  private

  def submit_tx
    return unless block_given?

    tx = Stellar::Transaction.for_account(
      account: user_keypair,
      sequence: user_account.next_sequence_value,
    )

    yield(tx.operations)

    tx.fee = FEE * tx.operations.size

    txe = tx.to_envelope(app_keypair).to_xdr(:base64)
    post_txe(txe).tap { [app_account, user_account].each(&:reload!) }
  end

  def post_txe(txe)
    Mobius::Client.horizon_client.horizon.transactions._post(tx: txe)
  end

  def payment_op(amount, dest:, src:)
    Stellar::Operation.payment(
      source_account: Mobius::Client.to_keypair(src),
      destination: Mobius::Client.to_keypair(dest),
      amount: Stellar::Amount.new(amount, Mobius::Client.stellar_asset).to_payment
    )
  end

  def validate!
    raise Mobius::Client::Error::AuthorisationMissing unless authorized?
    raise Mobius::Client::Error::TrustlineMissing unless user_account.trustline_exists?
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

  def handle(err)
    ops = err.response.dig(:body, "extras", "result_codes", "operations")
    raise Mobius::Client::Error::AccountMissing if ops.include?("op_no_destination")
    raise Mobius::Client::Error::TrustlineMissing if ops.include?("op_no_trust")
    raise err
  end

  def cast_amount(amount)
    Float(amount).to_d
  rescue ArgumentError
    raise Mobius::Client::Error::InvalidAmount, "Invalid amount provided: `#{amount}`"
  end

  FEE = 100
end
