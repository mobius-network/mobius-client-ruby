# Calls Stellar FriendBot
class Mobius::Client::Blockchain::FriendBot
  extend Dry::Initializer
  extend ConstructorShortcut[:call]

  param :keypair

  def call
    Mobius::Client.horizon_client.horizon.friendbot._post(addr: keypair.address)
  end
end
