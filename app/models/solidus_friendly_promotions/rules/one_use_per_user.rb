# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    class OneUsePerUser < PromotionRule
      include OrderLevelRule

      def eligible?(order, _options = {})
        if order.user.present?
          if promotion.used_by?(order.user, [order])
            eligibility_errors.add(
              :base,
              eligibility_error_message(:limit_once_per_user),
              error_code: :limit_once_per_user
            )
          end
        else
          eligibility_errors.add(:base, eligibility_error_message(:no_user_specified), error_code: :no_user_specified)
        end

        eligibility_errors.empty?
      end
    end
  end
end
