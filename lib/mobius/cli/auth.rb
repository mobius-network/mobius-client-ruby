require "uri"
require "thor"
require "faraday"
require "faraday_middleware"

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
  desc "token <URL> <User secret> <App public>", "Obtain auth token from application"
  def token(url, user_seed, app_public)
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

    say "Token:"
    say response.body
  rescue Mobius::Client::Error::Unauthorized
    say "Application signature wrong! Check application public key.", :red
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
