# frozen_string_literal: true

module SolidusFriendlyPromotions::OrderDecorator
    def self.prepended(base)
      base.has_many :friendly_order_promotions, class_name: "SolidusFriendlyPromotions::OrderPromotion", inverse_of: :order
      base.has_many :friendly_promotions, through: :friendly_order_promotions, source: :promotion
    end

    def ensure_promotions_eligible
      Spree::Config.promotion_adjuster_class.new(self).call
      if promo_total_changed?
        restart_checkout_flow
        recalculate
        errors.add(:base, I18n.t('solidus_friendly_promotions.promotion_total_changed_before_complete'))
      end

      super
    end

    Spree::Order.prepend self
  end
