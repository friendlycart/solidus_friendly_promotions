# frozen_string_literal: true

require "spec_helper"
require "solidus_friendly_promotions/promotion_migrator"
require "solidus_friendly_promotions/promotion_map"

RSpec.describe SolidusFriendlyPromotions::PromotionMigrator do
  let(:promotion_map) { SolidusFriendlyPromotions::PROMOTION_MAP }
  let!(:spree_promotion) { create(:promotion, :with_action, :with_item_total_rule, apply_automatically: true) }

  subject(:promotion_migrator) { SolidusFriendlyPromotions::PromotionMigrator.new(promotion_map).call }

  context "when an existing promotion has a promotion category" do
    let(:spree_promotion_category) { create(:promotion_category, name: "Sith") }
    let(:spree_promotion) { create(:promotion, promotion_category: spree_promotion_category) }

    it "creates promotion categories that match the old promotion categories" do
      expect { subject }.to change { SolidusFriendlyPromotions::PromotionCategory.count }.by(1)
      promotion_category = SolidusFriendlyPromotions::PromotionCategory.first
      expect(promotion_category.name).to eq("Sith")
    end
  end

  context "when an existing promotion has promotion codes" do
    let(:spree_promotion) { create(:promotion, code: "ANDOR LIFE") }

    it "creates codes for the new promotion, identical to the previous one" do
      expect { subject }.to change { SolidusFriendlyPromotions::PromotionCode.count }.by(1)
      promotion_code = SolidusFriendlyPromotions::PromotionCode.first
      expect(promotion_code.value).to eq("andor life")
    end
  end
end
