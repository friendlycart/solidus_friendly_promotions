# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    class UserRole < PromotionRule
      include OrderLevelRule

      preference :role_ids, :array, default: []

      MATCH_POLICIES = %w[any all].freeze
      preference :match_policy, default: MATCH_POLICIES.first

      def eligible?(order, _options = {})
        return false unless order.user

        if all_match_policy?
          match_all_roles?(order)
        else
          match_any_roles?(order)
        end
      end

      private

      def all_match_policy?
        preferred_match_policy == "all" && preferred_role_ids.present?
      end

      def user_roles(order)
        order.user.spree_roles.where(id: preferred_role_ids)
      end

      def match_all_roles?(order)
        user_roles(order).count == preferred_role_ids.count
      end

      def match_any_roles?(order)
        user_roles(order).exists?
      end
    end
  end
end
