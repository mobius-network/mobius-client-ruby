require "bundler/setup"
require "sinatra"
require "mobius/client"

keypair = Stellar::KeyPair.random

set :public_folder, "public"

get "/" do
  slim :index, locals: { app_public_key: keypair.address }
end

# Generates challenge transaction signed with application private key.
get "/auth" do
  Mobius::Client::Auth::Challenge.call(keypair.seed)
end

post "/auth" do
  begin
    token = Mobius::Client::Auth::Token.new(keypair.seed, params[:xdr], params[:public_key])
    token.validate!
    token.hash(:hex)
  rescue Mobius::Client::Auth::Token::Unauthorized
    "Access denied!"
  rescue Mobius::Client::Auth::Token::Expired
    "Session expired!"
  rescue Mobius::Client::Auth::Token::TooOld
    "Challenge expired!"
  end
end
