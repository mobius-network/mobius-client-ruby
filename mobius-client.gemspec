lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mobius/client/version"

Gem::Specification.new do |spec|
  spec.name          = "mobius-client"
  spec.version       = Mobius::Client::VERSION
  spec.authors       = ["Viktor Sokolov"]
  spec.email         = ["gzigzigzeo@gmail.com"]

  spec.summary       = %(Mobius Ruby Client)
  spec.description   = %(Mobius Ruby Client)
  spec.homepage      = "https://github.com/mobius-network/mobius-client-ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.respond_to?(:metadata) || raise("RubyGems 2.0 or newer is required to protect against public gem pushes.")
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "bundler-audit", "~> 0.6.0"
  spec.add_development_dependency "httplog", "~> 1.0", ">= 1.0.2"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.53"
  spec.add_development_dependency "rubocop-rspec", "~> 1.23"
  spec.add_development_dependency "simplecov", ">= 0.16.1"
  spec.add_development_dependency "simplecov-console", ">= 0.4.2"
  spec.add_development_dependency "timecop", "~> 0.9", ">= 0.9.1"
  spec.add_development_dependency "vcr", "~> 3.0", ">= 3.0.3"
  spec.add_development_dependency "webmock", "~> 3.3"
  spec.add_development_dependency "yard", "~> 0.9", ">= 0.9.12"

  spec.add_dependency "constructor_shortcut", "~> 0.2.0"
  spec.add_dependency "dry-initializer", "~> 2.4"
  spec.add_dependency "faraday", ">= 0.14"
  spec.add_dependency "faraday_middleware", "~> 0.12", ">= 0.12.2"
  spec.add_dependency "jwt", "~> 1.5", ">= 1.5.6"
  spec.add_dependency "stellar-sdk", "~> 0.6"
  spec.add_dependency "thor", "~> 0.20"
end
