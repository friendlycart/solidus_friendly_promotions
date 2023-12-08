# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Actions
    class AdjustLineItem < PromotionAction
      include LineItemLevelAction

      def can_discount?(object)
        object.is_a? Spree::LineItem
      end
    end
  end
end
