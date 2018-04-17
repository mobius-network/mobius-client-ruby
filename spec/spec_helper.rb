require "bundler/setup"
require "timecop"
require "vcr"
require "simplecov"
require "simplecov-console"

SimpleCov.formatter = SimpleCov.formatter = SimpleCov::Formatter::Console if ENV["CC_TEST_REPORTER_ID"]
SimpleCov.start

require "mobius/client"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
