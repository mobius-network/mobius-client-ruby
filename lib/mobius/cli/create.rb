require "thor"
require "net/http"

class Mobius::Cli::Create < Thor
  desc "account", "Create DApp Store account"
  def account
    say "Calling Mobius FriendBot..."
    keypair = Stellar::KeyPair.random
    Mobius::Client::FriendBot.call(keypair.seed)
    say " - Public Key: #{keypair.address}"
    say " - Private Key: #{keypair.seed}"
    say " - MOBI balance: #{Mobius::Account.new(keypair).balance}"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end

  desc "user", "Create user account"
  def user
    say "Hello"
  end
end
