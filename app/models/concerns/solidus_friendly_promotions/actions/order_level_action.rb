# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Actions
    module OrderLevelAction
      def can_discount?(_)
        false
      end

      def level
        :order
      end
    end
  end
end
