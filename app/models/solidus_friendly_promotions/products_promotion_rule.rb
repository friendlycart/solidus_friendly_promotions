# frozen_string_literal: true

module SolidusFriendlyPromotions
  class ProductsPromotionRule < Spree::Base
    belongs_to :product, class_name: "Spree::Product", optional: true
    belongs_to :promotion_rule, class_name: "SolidusFriendlyPromotions::PromotionRule", optional: true
  end
end
