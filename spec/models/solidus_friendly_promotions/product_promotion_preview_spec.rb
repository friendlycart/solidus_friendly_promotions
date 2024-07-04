# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusFriendlyPromotions::ProductPromotionPreview do
  let(:order) { create(:order) }
  let(:product) { create(:product) }
  let!(:variant_one) { create(:variant, price: 10, product: product) }
  let!(:variant_two) { create(:variant, price: 20, product: product) }

  subject { described_class.new(product: product, order: order).call }

  context "with no active promotions" do
    it { is_expected.to eq({
      variant_one.id => [],
      variant_two.id => []
    }) }
  end

  context "with an active promotion" do
    let!(:promotion) { create(:friendly_promotion, :with_adjustable_action, apply_automatically: true) }

    it { is_expected.to match({
      variant_one.id => an_instance_of(Array),
      variant_two.id => an_instance_of(Array)
    }) }

    it "does not change the order" do
      expect { subject }.not_to change { order.line_items }
    end
  end
end
