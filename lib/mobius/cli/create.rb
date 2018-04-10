require "thor"
require "erb"

class Mobius::Cli::Create < Mobius::Cli::Base
  desc "dapp_account", "Create DApp Store account funded with MOBI and XLM (test network only)"
  method_option :application, type: :string, aliases: "-a"
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def dapp_account
    keypair = create_dapp_account

    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * MOBI balance: #{Mobius::Client::Blockchain::Account.new(keypair).balance}"

    if options["application"]
      app_keypair = Mobius::Client.to_keypair(options["application"])
      add_cosigner(keypair, app_keypair)
    end
    say "Done!"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  desc "account", "Create regular Stellar account funded with XLM only (test network)"
  def account
    keypair = create_account

    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * XLM balance: #{Mobius::Client::Blockchain::Account.new(keypair).balance(:native)}"
    say "Done!"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  desc "dev-wallet", "Create wallet-dev.html"
  def dev_wallet
    # app_keypair = create_dapp_account(0)
    # normal_keypair = create_dapp_account(1000)
    # add_cosigner(normal_keypair, app_keypair)
    # zero_balance_keypair = create_dapp_account(0)
    # unauthorized_keypair = create_account

    app_keypair = Stellar::KeyPair.random
    normal_keypair = Stellar::KeyPair.random
    zero_balance_keypair = Stellar::KeyPair.random
    unauthorized_keypair = Stellar::KeyPair.random

    vars = {
      app: app_keypair,
      normal: normal_keypair,
      zero_balance: zero_balance_keypair,
      unauthorized: unauthorized_keypair
    }

    t = File.read(TEMPLATE)
    r = ERB.new(t).result(OpenStruct.new(vars).instance_eval { binding })
    File.open("dev-wallet.html", "w+") { |f| f.puts r }

    say "dev-wallet.html created. Copy it to your public web server directory and do not forget to change the URL!"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  no_commands do
    def create_dapp_account(amount = 1000)
      say "Calling Mobius FriendBot..."
      Stellar::KeyPair.random.tap do |keypair|
        Mobius::Client::FriendBot.call(keypair.seed, amount)
      end
    end

    def create_account
      say "Calling Stellar FriendBot..."
      Stellar::KeyPair.random.tap do |keypair|
        Mobius::Client::Blockchain::FriendBot.call(keypair)
      end
    end

    def add_cosigner(keypair, app_keypair)
      say "Adding cosigner..."
      Mobius::Client::Blockchain::AddCosigner.call(keypair, app_keypair)
    end
  end

  TEMPLATE = File.join(File.dirname(__FILE__), "../../../template/dev-wallet.html.erb").freeze
end
