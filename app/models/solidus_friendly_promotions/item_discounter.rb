# frozen_string_literal: true

module SolidusFriendlyPromotions
  class ItemDiscounter
    attr_reader :promotions, :eligibility_errors

    def initialize(promotions:, eligibility_errors: nil)
      @promotions = promotions
    end

    def call(item, eligibility_errors: nil)
      eligible_promotions = PromotionsEligibility.new(
        promotable: item,
        possible_promotions: promotions
      ).call

      eligible_promotions.flat_map do |promotion|
        promotion.actions.select do |action|
          action.can_discount?(item)
        end.map do |action|
          action.discount(item)
        end
      end
    end
  end
end
