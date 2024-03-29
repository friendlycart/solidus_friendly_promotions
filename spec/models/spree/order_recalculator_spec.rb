# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::Config.order_recalculator_class do
  let(:order) { create(:order) }
  subject { described_class.new(order).recalculate }

  it "calls the order promotion syncer" do
    expect_any_instance_of(SolidusFriendlyPromotions::MigrationSupport::OrderPromotionSyncer).to receive(:call)
    subject
  end

  context "if config option is set to false" do
    around do |example|
      SolidusFriendlyPromotions.config.sync_order_promotions = false
      example.run
      SolidusFriendlyPromotions.config.sync_order_promotions = true
    end

    it "does not call the order promotion syncer" do
      expect(SolidusFriendlyPromotions::MigrationSupport::OrderPromotionSyncer).not_to receive(:new)
      subject
    end
  end
end
