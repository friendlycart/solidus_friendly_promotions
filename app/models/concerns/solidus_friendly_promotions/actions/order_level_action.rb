# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Actions
    module OrderLevelAction
      extend ActiveSupport::Concern

      class_methods do
        def level
          :order
        end
      end

      def can_discount?(_)
        false
      end

      def level
        self.class.level
      end
    end
  end
end
