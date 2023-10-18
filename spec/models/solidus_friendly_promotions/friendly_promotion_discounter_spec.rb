# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::FriendlyPromotionDiscounter do
  context "shipped orders" do
    let(:promotions) { [] }
    let(:order) { create(:order, shipment_state: "shipped") }

    subject { described_class.new(order, promotions).call }

    it "returns nil" do
      expect(subject).to be nil
    end
  end
end
