# Generates JWT token based on valid token transaction signed by both parties and decodes JWT token into hash.
class Mobius::Client::Auth::Jwt
  extend Dry::Initializer

  # @!method initialize(secret)
  # @param secret [String] JWT secret
  # @!scope instance
  param :secret

  # Returns JWT token.
  # @param token [Mobius::Client::Auth::Token] Valid auth token
  # @return [String] JWT token
  def encode(token, options = {})
    payload = {
      jti: token.hash(:hex),
      sub: token.address,
      iat: token.time_bounds.min_time,
      exp: token.time_bounds.max_time
    }.merge(options)

    JWT.encode(payload, secret, ALG)
  end

  # Returns decoded JWT token.
  # @param jwt [String] JWT token
  # @return [Hash] Decoded token params
  def decode!(jwt)
    OpenStruct.new(JWT.decode(jwt, secret, true, algorithm: ALG).first)
  rescue JWT::ExpiredSignature => _
    raise TokenExpired
  end

  # Used JWT algorithm
  ALG = "HS512".freeze
end
