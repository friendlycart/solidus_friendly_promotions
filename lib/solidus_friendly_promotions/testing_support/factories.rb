# frozen_string_literal: true

module SolidusFriendlyPromotions
  def self.table_name_prefix
  "friendly_"
  end
end
require "solidus_friendly_promotions/testing_support/friendly_promotion_code_factory"
require "solidus_friendly_promotions/testing_support/friendly_promotion_category_factory"
require "solidus_friendly_promotions/testing_support/friendly_promotion_factory"
require "solidus_friendly_promotions/testing_support/friendly_order_promotion_factory"
require "solidus_friendly_promotions/testing_support/friendly_order_factory"

FactoryBot.define do
end
