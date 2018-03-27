# Checks challenge transaction signed by user on developer's side.
class Mobius::Client::Auth::Token
  extend Dry::Initializer

  # Raised if transaction one of transaction signatures is wrong.
  class Unauthorized < StandardError; end

  # Raised if transaction is invalid or time bounds are missing.
  class Invalid < StandardError; end

  # Raised if transaction has expired.
  class Expired < StandardError; end

  # Raised if transaction has expired (strict mode).
  class TooOld < StandardError; end

  # @!method initialize(seed, xdr, address)
  # @param seed [String] Developers private key.
  # @param xdr [String] Auth transaction XDR.
  # @param address [String] User public key.
  # @!scope instance
  param :seed
  param :xdr
  param :address

  # Returns time bounds for given transaction.
  #
  # @return [Stellar::TimeBounds] Time bounds for given transaction (`.min_time` and `.max_time`).
  # @raise [Unauthorized] if one of the signatures is invalid.
  # @raise [Invalid] if transaction is malformed or time bounds are missing.
  def time_bounds
    bounds = envelope.tx.time_bounds

    raise Unauthorized unless signed_correctly?
    raise Invalid if bounds.nil?

    bounds
  end

  # Validates transaction signed by developer and user.
  #
  # @param strict [Bool] if true, checks that lower time limit is within Mobius::Client.strict_interval seconds from now
  # @return [Boolean] true if transaction is valid, raises exception otherwise
  # @raise [Unauthorized] if one of the signatures is invalid
  # @raise [Invalid] if transaction is malformed or time bounds are missing
  # @raise [Expired] if transaction is expired (current time outside it's time bounds)
  def validate!(strict = true)
    bounds = time_bounds
    raise Expired unless time_now_covers?(bounds)
    raise TooOld if strict && too_old?(bounds)
    true
  end

  # @return [String] transaction hash
  def hash(format = :binary)
    h = envelope.tx.hash
    return h if format == :binary
    h.unpack("H*").first
  end

  private

  # @return [Stellar::KeyPair] Stellar::KeyPair object for given seed
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  # @return [Stellar::KeyPair] Stellar::KeyPair of user being authorized
  def their_keypair
    @their_keypair ||= Stellar::KeyPair.from_address(address)
  end

  # @return [Stellar::TrnansactionEnvelope] Stellar::TrnansactionEnvelope of challenge transaction
  def envelope
    @envelope ||= Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
  end

  # @return [Bool] true if transaction is signed by both parties
  def signed_correctly?
    envelope.signed_correctly?(keypair, their_keypair)
  end

  def time_now_covers?(time_bounds)
    (time_bounds.min_time..time_bounds.max_time).cover?(Time.now.to_i)
  end

  def too_old?(time_bounds)
    Time.now.to_i > time_bounds.min_time + Mobius::Client.strict_interval
  end
end
