# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Admin
    class PromotionGroupsController < Spree::Admin::ResourceController
      def index
        @promotion_groups = model_class.order(:position)
      end

      private

      def model_class
        SolidusFriendlyPromotions::PromotionGroup
      end

      def routes_proxy
        solidus_friendly_promotions
      end
    end
  end
end
