module SolidusFriendlyPromotions
  module Actions
    module LineItemLevelAction
      extend ActiveSupport::Concern

      class_methods do
        def level
          :line_item
        end
      end

      def level
        self.class.level
      end
    end
  end
end
