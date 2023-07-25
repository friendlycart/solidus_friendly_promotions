# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Promotion System" do
  context "A promotion that creates line item adjustments" do
    let(:shirt) { create(:product, name: "Shirt") }
    let(:pants) { create(:product, name: "Pants") }
    let(:promotion) { create(:friendly_promotion, name: "20% off Shirts", apply_automatically: true) }
    let(:order) { create(:order) }

    before do
      promotion.rules << rule
      promotion.actions << action
      order.contents.add(shirt.master, 1)
      order.contents.add(pants.master, 1)
    end

    context "with an order-level rule" do
      let(:rule) { SolidusFriendlyPromotions::Rules::Product.new(products: [shirt]) }

      context "with an line item level action" do
        let(:calculator) { SolidusFriendlyPromotions::Calculators::Percent.new(preferred_percent: 20) }
        let(:action) { SolidusFriendlyPromotions::Actions::AdjustLineItem.new(calculator: calculator) }

        it "creates one line item level adjustment" do
          expect(order.adjustments).to be_empty
          expect(order.total).to eq(31.98)
          expect(order.item_total).to eq(39.98)
          expect(order.item_total_before_tax).to eq(31.98)
          expect(order.line_items.flat_map(&:adjustments).length).to eq(2)
        end
      end
    end

    context "with a line-item level rule" do
      let(:rule) { SolidusFriendlyPromotions::Rules::LineItemProduct.new(products: [shirt]) }

      context "with an line item level action" do
        let(:calculator) { SolidusFriendlyPromotions::Calculators::Percent.new(preferred_percent: 20) }
        let(:action) { SolidusFriendlyPromotions::Actions::AdjustLineItem.new(calculator: calculator) }

        it "creates one line item level adjustment" do
          expect(order.adjustments).to be_empty
          expect(order.total).to eq(35.98)
          expect(order.item_total).to eq(39.98)
          expect(order.item_total_before_tax).to eq(35.98)
          expect(order.line_items.flat_map(&:adjustments).length).to eq(1)
        end
      end
    end
  end

  context "with a shipment-level rule" do
    let!(:ups_ground) { create(:shipping_method) }
    let!(:dhl_saver) { create(:shipping_method) }
    let(:promotion) { create(:friendly_promotion, name: "20 percent off UPS Ground", apply_automatically: true) }
    let(:rule) { SolidusFriendlyPromotions::Rules::ShippingMethod.new(preferred_shipping_method_ids: [ups_ground.id]) }
    let(:order) { create(:order_with_line_items, shipping_method: shipping_method) }

    before do
      promotion.rules << rule
      promotion.actions << action
    end

    context "with a line item level action" do
      let(:calculator) { SolidusFriendlyPromotions::Calculators::Percent.new(preferred_percent: 20) }
      let(:action) { SolidusFriendlyPromotions::Actions::AdjustLineItem.new(calculator: calculator) }
      let(:shipping_method) { ups_ground }

      it "creates adjustments" do
        expect(order.adjustments).to be_empty
        expect(order.total).to eq(108.00)
        expect(order.item_total).to eq(10)
        expect(order.item_total_before_tax).to eq(8)
        expect(order.promo_total).to eq(-2)
        expect(order.line_items.flat_map(&:adjustments).length).to eq(1)
        expect(order.shipments.flat_map(&:adjustments)).to be_empty
      end
    end

    context "with a shipment level action" do
      let(:calculator) { SolidusFriendlyPromotions::Calculators::Percent.new(preferred_percent: 20) }
      let(:action) { SolidusFriendlyPromotions::Actions::AdjustShipment.new(calculator: calculator) }

      context "when the order is eligible" do
        let(:shipping_method) { ups_ground }
        it "creates adjustments" do
          expect(order.adjustments).to be_empty
          expect(order.total).to eq(90)
          expect(order.item_total).to eq(10)
          expect(order.item_total_before_tax).to eq(10)
          expect(order.line_items.flat_map(&:adjustments)).to be_empty
          expect(order.shipments.flat_map(&:adjustments)).not_to be_empty
        end
      end

      context "when the order is not eligible" do
        let(:shipping_method) { dhl_saver }

        it "creates no adjustments" do
          expect(order.adjustments).to be_empty
          expect(order.total).to eq(110)
          expect(order.item_total).to eq(10)
          expect(order.item_total_before_tax).to eq(10)
          expect(order.promo_total).to eq(0)
          expect(order.line_items.flat_map(&:adjustments)).to be_empty
          expect(order.shipments.flat_map(&:adjustments)).to be_empty
        end
      end
    end
  end
end
