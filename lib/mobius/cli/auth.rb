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

  # desc "challenge <App public> <URL>", "Obtain challenge transaction from application and verify it"
  # def challenge(app_public)
  #   say "Challenge transaction XDR:"
  #   say Mobius::Client::Auth::Challenge.call(user_seed, 3600 * 24)
  # end
  #
  # desc "auth <User secret> <App public> <URL>", "Obtain auth token from application"
  # def auth(user_seed, app_public, url)
  #   say "Challenge transaction XDR:"
  #   say Mobius::Client::Auth::Challenge.call(user_seed, 3600 * 24)
  #
  #   say "POST #{url}..."
  #   say
  # end
end
