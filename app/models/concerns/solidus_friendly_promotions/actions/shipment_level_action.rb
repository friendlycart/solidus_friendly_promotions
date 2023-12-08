module SolidusFriendlyPromotions
  module Actions
    module ShipmentLevelAction
      extend ActiveSupport::Concern

      class_methods do
        def level
          :shipment
        end
      end

      def level
        self.class.level
      end
    end
  end
end
