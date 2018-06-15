require "constructor_shortcut"
require "dry-initializer"
require "stellar-sdk"
require "faraday"
require "faraday_middleware"
require "jwt"

require "mobius/client/version"

begin
  require "pry-byebug"
rescue LoadError
end

module Mobius
  module Cli
    autoload :Base,   "mobius/cli/base"
    autoload :App,    "mobius/cli/app"
    autoload :Auth,   "mobius/cli/auth"
    autoload :Create, "mobius/cli/create"
  end

  module Client
    autoload :Error,     "mobius/client/error"
    autoload :FriendBot, "mobius/client/friend_bot"
    autoload :App,       "mobius/client/app"

    module Auth
      autoload :Challenge, "mobius/client/auth/challenge"
      autoload :Jwt,       "mobius/client/auth/jwt"
      autoload :Sign,      "mobius/client/auth/sign"
      autoload :Token,     "mobius/client/auth/token"
    end

    module Blockchain
      autoload :Account,         "mobius/client/blockchain/account"
      autoload :AddCosigner,     "mobius/client/blockchain/add_cosigner"
      autoload :CreateTrustline, "mobius/client/blockchain/create_trustline"
      autoload :FriendBot,       "mobius/client/blockchain/friend_bot"
      autoload :KeyPairFactory,  "mobius/client/blockchain/key_pair_factory"
    end

    class << self
      attr_writer :mobius_host

      # Mobius API host
      def mobius_host
        @mobius_host ||= "https://mobius.network"
      end

      def network=(value)
        @network = value
        Stellar.default_network = stellar_network
      end

      # Stellar network to use (:test || :public). See notes on thread-safety in ruby-stellar-base.
      # Safe to set on startup.
      def network
        @network ||= :test
      end

      # `Stellar::Client` instance
      attr_writer :horizon_client

      def horizon_client
        @horizon_client ||= network == :test ? Stellar::Client.default_testnet : Stellar::Client.default
      end

      # Asset code used for payments (MOBI by default)
      attr_writer :asset_code

      def asset_code
        @asset_code ||= "MOBI"
      end

      # Asset issuer account
      attr_writer :asset_issuer

      def asset_issuer
        return @asset_issuer if @asset_issuer
        return "GA6HCMBLTZS5VYYBCATRBRZ3BZJMAFUDKYYF6AH6MVCMGWMRDNSWJPIH" if network == :public
        "GDRWBLJURXUKM4RWDZDTPJNX6XBYFO3PSE4H4GPUL6H6RCUQVKTSD4AT"
      end

      # Challenge expires in (seconds, 1d by default)
      attr_writer :challenge_expires_in

      def challenge_expires_in
        @challenge_expires_in ||= 60 * 60 * 24
      end

      # Stellar::Asset instance of asset used for payments
      def stellar_asset
        @stellar_asset ||= Stellar::Asset.alphanum4(asset_code, Stellar::KeyPair.from_address(asset_issuer))
      end

      # In strict mode, session must be not older than seconds from now (10 by default)
      attr_writer :strict_interval

      def strict_interval
        @strict_interval ||= 10
      end

      # Runs block on selected Stellar network
      def on_network
        Stellar.on_network(stellar_network) do
          yield if block_given?
        end
      end

      # Converts given argument to Stellar::KeyPair
      def to_keypair(subject)
        Mobius::Client::Blockchain::KeyPairFactory.produce(subject)
      end

      private

      def stellar_network
        Mobius::Client.network == :test ? Stellar::Networks::TESTNET : Stellar::Networks::PUBLIC
      end
    end
  end
end
