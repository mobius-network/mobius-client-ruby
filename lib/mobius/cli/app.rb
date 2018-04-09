require "thor"

class Mobius::Cli::App < Mobius::Cli::Base
  def self.exit_on_failure?
    true
  end

  class_option :production, desc: "Use production network", default: false, aliases: "-p", type: :boolean

  desc "create", "Create various assets"
  subcommand "create", Mobius::Cli::Create

  desc "auth", "Authorize and authenticate user"
  subcommand "auth", Mobius::Cli::Auth
end
