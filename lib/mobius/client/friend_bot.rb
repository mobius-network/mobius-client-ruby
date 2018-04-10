class Mobius::Client::FriendBot
  extend Dry::Initializer

  param :seed
  param :amount, default: -> { 1000 }

  def call
    response = http.post(ENDPOINT, addr: seed, amount: amount)
    return true if response.success?
    raise "FriendBot failed to respond: #{response.body}"
  end

  class << self
    def call(*args)
      new(*args).call
    end
  end

  private

  def http
    # Mobius::Client.mobius_host
    Faraday.new("https://localhost:4000", :ssl => {:verify => false}) do |c|
      c.request :url_encoded
      c.response :json, content_type: /\bjson$/
      c.adapter Faraday.default_adapter
    end
  end

  ENDPOINT = "/api/stellar/friendbot".freeze
end
