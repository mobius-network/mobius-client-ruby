require "dry-initializer"
require "stellar-sdk"

require "mobius/client/version"

module Mobius
  module Cli
    autoload :App, "mobius/cli/app"
    autoload :Create, "mobius/cli/create"
  end

  module Client
    module Error
      autoload :AccountMissing,       "mobius/client/error/account_missing"
      autoload :TrustlineMissing,     "mobius/client/error/trustline_missing"
      autoload :Unauthorized,         "mobius/client/error/unauthorized"
      autoload :MalformedTransaction, "mobius/client/error/malformed_transaction"
      autoload :TokenExpired,         "mobius/client/error/token_expired"
      autoload :TokenTooOld,          "mobius/client/error/token_too_old"
    end

    module Auth
      autoload :Challenge, "mobius/client/auth/challenge"
      autoload :Sign,      "mobius/client/auth/sign"
      autoload :Token,     "mobius/client/auth/token"
    end

    module Blockchain
      autoload :Account,   "mobius/client/blockchain/account"
    end

    class << self
      # Stellar network to use (:test || :public)
      attr_writer :network

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

      # Challenge expires in (seconds, 1h by default)
      attr_writer :challenge_expires_in

      def challenge_expires_in
        @challenge_expires_in ||= 60 * 60 * 24
      end

      # Session considered valid if issued not later than seconds (10 by default)
      attr_writer :session_valid_in

      def session_valid_in
        @session_valid_in ||= 15
      end

      # Stellar::Asset instance of asset used for payments
      def stellar_asset
        Stellar::Asset.alphanum4(asset_code, Stellar::KeyPair.from_address(asset_issuer))
      end

      # In strict mode, session must be not older than seconds from now (10 by default)
      attr_writer :strict_interval

      def strict_interval
        @strict_interval ||= 10
      end

      # Runs block on selected Stellar network
      def on_network
        Stellar.on_network(Mobius::Client.network == :test ? Stellar::Networks::TESTNET : Stellar::Networks::PUBLIC) do
          yield if block_given?
        end
      end
    end
  end
end
