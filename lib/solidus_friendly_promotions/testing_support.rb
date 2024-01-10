# frozen_string_literal: true

# Dir[::SolidusFriendlyPromotions::Engine.root.join("app", "models", "solidus_friendly_promotions", "friendly_promotion_adjuster", "*.rb")].each { |file| require file }

module SolidusFriendlyPromotions
  module TestingSupport
    def self.factories_path
      ::SolidusFriendlyPromotions::Engine.root.join("lib", "solidus_friendly_promotions", "testing_support", "factories")
    end
  end
end
