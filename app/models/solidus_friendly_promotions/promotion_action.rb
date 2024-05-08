# frozen_string_literal: true

require "spree/preferences/persistable"

module SolidusFriendlyPromotions
  # Base class for all types of promotion action.
  #
  # PromotionActions perform the necessary tasks when a promotion is activated
  # by an event and determined to be eligible.
  class PromotionAction < Spree::Base
    include Spree::Preferences::Persistable
    include Spree::CalculatedAdjustments
    include Spree::AdjustmentSource
    before_destroy :remove_adjustments_from_incomplete_orders
    before_destroy :raise_for_adjustments_for_completed_orders

    belongs_to :promotion, inverse_of: :actions
    belongs_to :original_promotion_action, class_name: "Spree::PromotionAction", optional: true
    has_many :adjustments, class_name: "Spree::Adjustment", as: :source
    has_many :shipping_rate_discounts, class_name: "SolidusFriendlyPromotions::ShippingRateDiscount", inverse_of: :promotion_action
    has_many :conditions, class_name: "SolidusFriendlyPromotions::Condition", inverse_of: :action, foreign_key: :action_id, dependent: :destroy

    scope :of_type, ->(type) { where(type: Array.wrap(type).map(&:to_s)) }

    def preload_relations
      [:calculator]
    end

    def can_discount?(object)
      raise NotImplementedError
    end

    def discount(adjustable)
      amount = compute_amount(adjustable)
      return if amount.zero?
      ItemDiscount.new(
        item: adjustable,
        label: adjustment_label(adjustable),
        amount: amount,
        source: self
      )
    end

    # Ensure a negative amount which does not exceed the object's amount
    def compute_amount(adjustable)
      promotion_amount = calculator.compute(adjustable) || BigDecimal("0")
      [adjustable.discountable_amount, promotion_amount.abs].min * -1
    end

    def adjustment_label(adjustable)
      I18n.t(
        "solidus_friendly_promotions.adjustment_labels.#{adjustable.class.name.demodulize.underscore}",
        promotion: SolidusFriendlyPromotions::Promotion.model_name.human,
        promotion_customer_label: promotion.customer_label
      )
    end

    def to_partial_path
      "solidus_friendly_promotions/admin/promotion_actions/actions/#{model_name.element}"
    end

    def level
      raise NotImplementedError
    end

    def available_conditions
      possible_conditions - conditions.select(&:persisted?)
    end

    def available_calculators
      SolidusFriendlyPromotions.config.promotion_calculators[self.class] || (raise NotImplementedError)
    end

    def eligible_by_applicable_conditions?(promotable, dry_run: false)
      applicable_conditions = conditions.select do |condition|
        condition.applicable?(promotable)
      end

      applicable_conditions.map do |applicable_condition|
        eligible = applicable_condition.eligible?(promotable)

        break [false] if !eligible && !dry_run

        if dry_run
          if applicable_condition.eligibility_errors.details[:base].first
            code = applicable_condition.eligibility_errors.details[:base].first[:error_code]
            message = applicable_condition.eligibility_errors.full_messages.first
          end
          promotion.eligibility_results.add(
            item: promotable,
            condition: applicable_condition,
            success: eligible,
            code: eligible ? nil : (code || :coupon_code_unknown_error),
            message: eligible ? nil : (message || I18n.t(:coupon_code_unknown_error, scope: [:solidus_friendly_promotions, :eligibility_errors]))
          )
        end

        eligible
      end.all?
    end

    def applicable_line_items(order)
      order.discountable_line_items.select do |line_item|
        eligible_by_applicable_conditions?(line_item)
      end
    end

    private

    def possible_conditions
      Set.new(SolidusFriendlyPromotions.config.order_conditions)
    end

    def raise_for_adjustments_for_completed_orders
      if adjustments.joins(:order).merge(Spree::Order.complete).any?
        errors.add(:base, :cannot_destroy_if_order_completed)
        throw(:abort)
      end
    end
  end
end
