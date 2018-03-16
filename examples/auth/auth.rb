require "bundler/setup"
require "sinatra"
require "mobius/client"

keypair = Stellar::KeyPair.random
auth = Mobius::Client::Auth.new(keypair.seed)

set :public_folder, "public"

get "/" do
  slim :index
end

get "/auth" do
  auth.challenge
end

post "/auth" do
  begin
    auth.validate!(params[:xdr], params[:public_key])
    "Valid!"
  rescue Mobius::Client::Auth::Unauthorized
    "Access denied!"
  rescue Mobius::Client::Auth::Expired
    "Session expired!"
  end
end
