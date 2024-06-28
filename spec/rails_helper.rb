# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "spec_helper"

# Create the dummy app if it's still missing.
dummy_env = "#{__dir__}/dummy/config/environment.rb"
system "bin/rake extension:test_app" unless File.exist? dummy_env
require dummy_env

# Turbo will try to autoload ActionCable if we allow `app/channels`.
# Backport of https://github.com/hotwired/turbo-rails/pull/601
# Can go once `turbo-rails` 2.0.7 is released.
Rails.autoloaders.once.do_not_eager_load("#{Turbo::Engine.root}/app/channels")

# Requires factories and other useful helpers defined in spree_core.
require "solidus_dev_support/rspec/feature_helper"
require "shoulda-matchers"
# Explicitly load activemodel mocks
require "rspec-activemodel-mocks"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

# Requires factories defined in Solidus core and this extension.
# See: lib/solidus_friendly_promotions/testing_support/factories.rb
SolidusDevSupport::TestingSupport::Factories.load_for(SolidusFriendlyPromotions::Engine)

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.include SolidusFriendlyPromotions::Engine.routes.url_helpers, type: :request
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
