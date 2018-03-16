require "dry-initializer"
require "stellar-sdk"

require "mobius/client/version"
require "mobius/client/auth"
require "mobius/client/app"

module Mobius
  module Client
    class << self
      attr_writer :network

      def network
        @network ||= :test
      end

      attr_writer :horizon_client

      def horizon_client
        @horizon_client ||= network == :test ? Stellar::Client.default_testnet : Stellar::Client.default
      end

      attr_writer :mobi_asset_code

      def asset_code
        @asset_code ||= "MOBI"
      end

      attr_writer :asset_issuer

      def asset_issuer
        return @asset_issuer if @asset_issuer
        return "GDRWBLJURXUKM4RWDZDTPJNX6XBYFO3PSE4H4GPUL6H6RCUQVKTSD4AT" if network == :public
        "GDRWBLJURXUKM4RWDZDTPJNX6XBYFO3PSE4H4GPUL6H6RCUQVKTSD4AT"
      end
    end
  end
end
