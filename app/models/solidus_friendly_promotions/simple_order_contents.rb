# frozen_string_literal: true

module SolidusFriendlyPromotions
  class SimpleOrderContents < Spree::OrderContents
    def update_cart(params)
      if order.update(params)
        unless order.completed?
          order.line_items = order.line_items.select { |li| li.quantity > 0 }
          order.check_shipments_and_restart_checkout
        end
        reload_totals
        true
      else
        false
      end
    end

    private

    def after_add_or_remove(line_item, options = {})
      shipment = options[:shipment]
      shipment.present? ? shipment.update_amounts : order.check_shipments_and_restart_checkout
      reload_totals
      line_item
    end
  end
end
