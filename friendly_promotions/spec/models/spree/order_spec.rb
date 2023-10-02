# frozen_string_literal: true

require "spec_helper"

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
end
