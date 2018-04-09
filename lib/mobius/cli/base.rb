class Mobius::Cli::Base < Thor
  protected

  no_commands do
    def use_network
      Mobius::Client.network = :public if options[:production]
    end
  end
end
