require "thor"

class Mobius::Cli::App < Thor
  def self.exit_on_failure?
    true
  end

  desc "create", "Create various assets"
  subcommand "create", Mobius::Cli::Create
end
