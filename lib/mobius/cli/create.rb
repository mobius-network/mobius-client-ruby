require "thor"
require "net/http"

class Mobius::Cli::Create < Thor
  desc "app", "Create application account"
  def app
    say "Hi!", :red
  end

  desc "user", "Create user account"
  def user
    say "Hello"
  end
end
