# frozen_string_literal: true

module SolidusFriendlyPromotions
  module PromotionHandler
    class Coupon
      attr_reader :order, :coupon_code
      attr_accessor :error, :success, :status_code

      def initialize(order)
        @order = order
        @coupon_code = order&.coupon_code&.downcase
      end

      def apply
        if coupon_code.present?
          if promotion.present? && promotion.active? && promotion.actions.exists?
            handle_present_promotion
          elsif promotion_code&.promotion&.expired?
            set_error_code :coupon_code_expired
          else
            set_error_code :coupon_code_not_found
          end
        end

        self
      end

      def remove
        if promotion.blank?
          set_error_code :coupon_code_not_found
        elsif !promotion_exists_on_order?(order, promotion)
          set_error_code :coupon_code_not_present
        else
          order.friendly_order_promotions.destroy_by(
            promotion: promotion
          )
          order.recalculate
          set_success_code :coupon_code_removed
        end

        self
      end

      def set_success_code(status_code)
        @status_code = status_code
        @success = I18n.t(status_code, scope: "spree")
      end

      def set_error_code(status_code, options = {})
        @status_code = status_code
        @error = options[:error] || I18n.t(status_code, scope: "spree")
      end

      def promotion
        @promotion ||= if promotion_code&.promotion&.active?
          promotion_code.promotion
        end
      end

      def successful?
        success.present? && error.blank?
      end

      private

      def promotion_code
        @promotion_code ||= SolidusFriendlyPromotions::PromotionCode.where(value: coupon_code).first
      end

      def handle_present_promotion
        return promotion_usage_limit_exceeded if promotion.usage_limit_exceeded? || promotion_code.usage_limit_exceeded?
        return promotion_applied if promotion_exists_on_order?(order, promotion)

        # Try applying this promotion, with no effects
        SolidusFriendlyPromotions::FriendlyPromotionDiscounter.new(order, [promotion]).call
        success_code = promotion.eligibility_errors.any? ? :connected_but_promotion_ineligible : :coupon_code_applied

        order.friendly_order_promotions.create!(
          promotion: promotion,
          promotion_code: promotion_code
        )
        order.recalculate
        set_success_code success_code
      end

      def set_promotion_eligibility_error_code(promotion)
        return unless eligibility_error_code_present?(promotion)

        eligibility_error = promotion.eligibility_errors.details[:base].first

        @status_code = eligibility_error[:error_code]
        @error = eligibility_error[:error]
      end

      def promotion_usage_limit_exceeded
        set_error_code :coupon_code_max_usage
      end

      def ineligible_for_this_order
        set_error_code :coupon_code_not_eligible
      end

      def promotion_applied
        set_error_code :coupon_code_already_applied
      end

      def promotion_exists_on_order?(order, promotion)
        order.friendly_promotions.include? promotion
      end

      def eligibility_error_code_present?(promotion)
        promotion.eligibility_errors.present? &&
          promotion.eligibility_errors.details.present? &&
          promotion.eligibility_errors.details.key?(:base) &&
          promotion.eligibility_errors.details[:base].first[:error_code].present?
      end
    end
  end
end
