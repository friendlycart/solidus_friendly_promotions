# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::Order do
  it { is_expected.to have_many :friendly_promotions }
  it { is_expected.to have_many :friendly_order_promotions }

  describe "#reset_current_discounts" do
    let(:line_item) { Spree::LineItem.new }
    let(:shipment) { Spree::Shipment.new }
    let(:order) { Spree::Order.new(shipments: [shipment], line_items: [line_item]) }

    subject { order.reset_current_discounts }

    it "resets the current discounts on all line items and shipments" do
      expect(line_item).to receive(:reset_current_discounts)
      expect(shipment).to receive(:reset_current_discounts)
      subject
    end
  end

  describe "order deletion" do
    let(:order) { create(:order) }
    let(:promotion) { create(:friendly_promotion) }

    subject { order.destroy }
    before do
      order.friendly_promotions << promotion
    end

    it "deletes join table entries when deleting an order" do
      expect { subject }.to change { SolidusFriendlyPromotions::OrderPromotion.count }.from(1).to(0)
    end
  end

  describe ".allowed_ransackable_associations" do
    subject { described_class.allowed_ransackable_associations }

    it { is_expected.to include("friendly_promotions", "friendly_order_promotions") }
  end
end
