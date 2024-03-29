# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Actions
    class CreateDiscountedItem < PromotionAction
      include OrderLevelAction
      preference :variant_id, :integer
      preference :quantity, :integer, default: 1
      preference :necessary_quantity, :integer, default: 1

      def perform(order)
        line_item = find_item(order) || create_item(order)
        set_quantity(line_item, determine_item_quantity(order))
        line_item.current_discounts << discount(line_item)
      end

      def remove_from(order)
        line_item = find_item(order)
        order.line_items.destroy(line_item)
      end

      private

      def find_item(order)
        order.line_items.detect { |line_item| line_item.managed_by_order_action == self }
      end

      def create_item(order)
        order.line_items.create!(quantity: determine_item_quantity(order), variant: variant, managed_by_order_action: self)
      end

      def determine_item_quantity(order)
        applicable_line_items = promotion.applicable_line_items(order)
        # Integer division will floor automatically, which is what we want here:
        # 1 Item, 2 needed: 1 * 1 / 2 => 0
        # 5 items, 2 preferred, 2 needed: 5 / 2 * 2 => 4
        applicable_line_items.sum(&:quantity) / preferred_necessary_quantity * preferred_quantity
      end

      def set_quantity(line_item, quantity)
        line_item.quantity_setter = self
        line_item.quantity = quantity
      end

      def variant
        Spree::Variant.find(preferred_variant_id)
      end
    end
  end
end
