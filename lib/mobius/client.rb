require "dry-initializer"
require "stellar-sdk"

require "mobius/client/version"
require "mobius/client/auth"
require "mobius/client/app"

module Mobius
  module Client
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
        return "GDRWBLJURXUKM4RWDZDTPJNX6XBYFO3PSE4H4GPUL6H6RCUQVKTSD4AT" if network == :public
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
    end
  end
end
