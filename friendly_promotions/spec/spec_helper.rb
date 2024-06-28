# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  if ENV["COVERAGE_DIR"]
    SimpleCov.coverage_dir(ENV["COVERAGE_DIR"])
  end
  SimpleCov.command_name("solidus:core")
  SimpleCov.merge_timeout(3600)
  SimpleCov.start("rails")
end

require "rspec/core"

require "spree/testing_support/flaky"
require "spree/testing_support/partial_double_verification"
require "spree/testing_support/silence_deprecations"
require "spree/testing_support/preferences"
require "spree/core"
require "spree/config"

require "shoulda-matchers"
# Explicitly load activemodel mocks
require "rspec-activemodel-mocks"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

require "solidus_friendly_promotions"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Spree::TestingSupport::Preferences

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.order = :random

  Kernel.srand config.seed
end
