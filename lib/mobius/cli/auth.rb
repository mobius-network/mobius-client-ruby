require "thor"

class Mobius::Cli::Auth < Thor
  desc "authorize <User secret> <App public>", "Authorize application to pay from user account"
  def authorize(user_seed, app_public_key)
    say "Adding cosigner..."
    user_keypair = Mobius::Client.to_keypair(user_seed)
    app_keypair = Mobius::Client.to_keypair(app_public_key)
    Mobius::Client::Blockchain::AddCosigner.call(user_keypair, app_keypair)
    say "#{app_keypair.address} is now authorized to withdraw from #{user_keypair.address}"
  end
end
