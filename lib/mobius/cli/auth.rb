require "uri"
require "thor"

class Mobius::Cli::Auth < Thor
  desc "authorize <User secret> <App public>", "Authorize application to pay from user account"
  def authorize(user_seed, app_public_key)
    say "Adding cosigner..."
    user_keypair = Mobius::Client.to_keypair(user_seed)
    app_keypair = Mobius::Client.to_keypair(app_public_key)
    Mobius::Client::Blockchain::AddCosigner.call(user_keypair, app_keypair)
    say "#{app_keypair.address} is now authorized to withdraw from #{user_keypair.address}"
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  desc "fetch <URL> <User secret> <App public>", "Obtain auth token from application"
  method_option :jwt, type: :string, aliases: "-j"
  def fetch(url, user_seed, app_public)
    keypair = Mobius::Client.to_keypair(user_seed)

    say "Requesting challenge..."

    uri = URI(url)
    conn = http("#{uri.scheme}://#{uri.host}:#{uri.port}")

    response = conn.get(uri.path)
    validate_response!(response)
    xdr = response.body

    say "Challenge:"
    say xdr
    say "Requesting token..."

    signed_xdr = Mobius::Client::Auth::Sign.call(keypair.seed, xdr, app_public)

    say "Signed challenge:"
    say signed_xdr

    response = conn.post(uri.path, xdr: signed_xdr, public_key: keypair.address)
    validate_response!(response)

    token = response.body

    say "Token (hash):"
    if options[:jwt]
      say Mobius::Client::Auth::Jwt.new(options[:jwt]).encode(token)
    else
      say token
    end
  rescue Mobius::Client::Error::Unauthorized
    say "Application signature wrong! Check application public key.", :red
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  desc "token <User secret> <App secret>", "Generate auth token locally"
  method_option :jwt, type: :string, aliases: "-j"
  def token(user_seed, app_seed)
    user_keypair = Mobius::Client.to_keypair(user_seed)
    app_keypair = Mobius::Client.to_keypair(app_seed)

    xdr = Mobius::Client::Auth::Challenge.call(app_seed)
    signed_xdr = Mobius::Client::Auth::Sign.call(user_seed, xdr, app_keypair.address)
    token = Mobius::Client::Auth::Token.new(app_seed, signed_xdr, user_keypair.address)

    say "Token:"
    if options[:jwt]
      say Mobius::Client::Auth::Jwt.new(options[:jwt]).encode(token)
    else
      say token.hash(:hex)
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  no_commands do
    def http(host)
      Faraday.new(host) do |c|
        c.request :url_encoded
        c.response :json, content_type: /\bjson$/
        c.adapter Faraday.default_adapter
      end
    end

    def validate_response!(response)
      return if response.success?
      say "[ERROR]: #{response.status} #{response.body}", :red
      exit(-1)
    end
  end
end
