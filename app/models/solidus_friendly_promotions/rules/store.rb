# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    class Store < PromotionRule
      include OrderLevelRule

      has_many :promotion_rules_stores, class_name: "SolidusFriendlyPromotions::PromotionRulesStore",
        foreign_key: :promotion_rule_id,
        dependent: :destroy
      has_many :stores, through: :promotion_rules_stores, class_name: "Spree::Store"

      def preload_relations
        [:stores]
      end

      def eligible?(order, _options = {})
        stores.none? || stores.include?(order.store)
      end

      def updateable?
        true
      end
    end
  end
end
