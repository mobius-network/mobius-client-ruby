class Mobius::Client::Auth::Jwt
  extend Dry::Initializer

  param :secret

  def encode(token)
    payload = {
      hash: token.hash(:hex),
      public_key: token.address,
      min_time: token.time_bounds.min_time,
      max_time: token.time_bounds.max_time
    }

    JWT.encode(payload, secret, ALG)
  end

  def decode!(jwt)
    OpenStruct.new(
      JWT.decode(jwt, secret, true, algorithm: ALG).first
    ).tap do |payload|
      raise TokenExpired unless (payload.min_time..payload.max_time).cover?(Time.now.to_i)
    end
  end

  ALG = "HS512".freeze
end
