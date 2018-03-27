class Mobius::Client::Blockchain::FriendBot
  extend Dry::Initializer

  param :keypair

  def call
    Mobius::Client.horizon_client.horizon.friendbot._post(addr: keypair.address)
  end

  class << self
    def call(*args)
      new(*args).call
    end
  end
end
