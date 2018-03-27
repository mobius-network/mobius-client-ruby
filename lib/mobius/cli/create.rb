require "thor"
require "net/http"

class Mobius::Cli::Create < Thor
  desc "dapp_account", "Create DApp Store account funded with MOBI and XLM"
  def dapp_account
    say "Calling Mobius FriendBot..."
    keypair = Stellar::KeyPair.random
    Mobius::Client::FriendBot.call(keypair.seed)
    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * MOBI balance: #{Mobius::Account.new(keypair).balance}"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end

  desc "account", "Create regular Stellar account funded with XLM only"
  def account
    say "Calling Stellar FriendBot..."
    keypair = Stellar::KeyPair.random
    Mobius::Client::Blockchain::FriendBot.call(keypair)
    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * XLM balance: #{Mobius::Client::Blockchain::Account.new(keypair).balance(:native)}"
  end
end
