# frozen_string_literal: true

module SolidusFriendlyPromotions
  class ProductPromotionPreview
    def initialize(product:, order:, quantity: 1)
      @product = product
      @order = order
      @quantity = quantity
    end

    def call
      product.variants.each do |variant|
        add_to_line_item(variant)
      end
      all_discounts = SolidusFriendlyPromotions.config.discounters.map do |discounter|
        discounter.new(order).call
      end
      line_item_discounts = all_discounts.flat_map(&:line_item_discounts)
      product.variants.inject({}) do |accumulator, variant|
        variant_promotions = line_item_discounts.select { |discount| discount.item.variant == variant }
        line_item = order.find_line_item_by_variant(variant)
        chosen_variant_promotions = SolidusFriendlyPromotions.config.discount_chooser_class.new(line_item).call(variant_promotions)
        remove_from_line_item(variant)
        accumulator[variant.id] = chosen_variant_promotions
        accumulator
      end
    end

    private

    def add_to_line_item(variant)
      line_item = order.find_line_item_by_variant(variant)

      line_item ||= order.line_items.new(
        quantity: 0,
        variant: variant
      )
      line_item.valid? # sets the price from the variant according to the order
      line_item.quantity += quantity.to_i
    end

    def remove_from_line_item(variant)
      line_item = order.find_line_item_by_variant(variant)
      line_item.quantity -= quantity
      order.line_items.delete(line_item) if line_item.quantity.zero?
    end

    attr_reader :product, :order, :quantity
  end
end
