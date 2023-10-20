# frozen_string_literal: true

module SolidusFriendlyPromotions
  class FriendlyPromotionDiscounter
    attr_reader :order, :promotions, :eligibility_errors

    def initialize(order)
      @order = order
      @promotions = PromotionLoader.new(order: order).call
      @eligibility_errors = ActiveModel::Errors.new(self)
      # @line_item_eligibility_errors = ActiveModel::Errors.new(self)
    end

    def call
      return nil if order.shipped?

      order.reset_current_discounts

      SolidusFriendlyPromotions::Promotion.ordered_lanes.each do |lane, _index|
        lane_promotions = PromotionsEligibility.new(
          promotable: order,
          possible_promotions: promotions.select { |promotion| promotion.lane == lane },
          eligibility_errors: eligibility_errors
        ).call
        item_discounter = ItemDiscounter.new(promotions: lane_promotions, eligibility_errors: eligibility_errors)
        line_item_discounts = adjust_line_items(item_discounter)
        shipment_discounts = adjust_shipments(item_discounter)
        shipping_rate_discounts = adjust_shipping_rates(item_discounter)
        (line_item_discounts + shipment_discounts + shipping_rate_discounts).each do |item, chosen_discounts|
          item.current_discounts.concat(chosen_discounts)
        end
      end

      order
    end

    private

    def adjust_line_items_across(promotions)
      promotions.each do |promotion|
        line_items.each do |line_item|

        end
      end
    end
    def adjust_line_items(item_discounter)
      order.line_items.select do |line_item|
        line_item.variant.product.promotionable?
      end.map do |line_item|

        discounts = item_discounter.call(line_item)
        chosen_item_discounts = SolidusFriendlyPromotions.config.discount_chooser_class.new(line_item).call(discounts)
        [line_item, chosen_item_discounts]
      end
    end

    def adjust_shipments(item_discounter)
      order.shipments.map do |shipment|
        discounts = item_discounter.call(shipment)
        chosen_item_discounts = SolidusFriendlyPromotions.config.discount_chooser_class.new(shipment).call(discounts)
        [shipment, chosen_item_discounts]
      end
    end

    def adjust_shipping_rates(item_discounter)
      order.shipments.flat_map(&:shipping_rates).map do |rate|
        discounts = item_discounter.call(rate)
        chosen_item_discounts = SolidusFriendlyPromotions.config.discount_chooser_class.new(rate).call(discounts)
        [rate, chosen_item_discounts]
      end
    end
  end
end
