# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusFriendlyPromotions::Promotion, type: :model do
  let(:promotion) { described_class.new }

  it { is_expected.to belong_to(:category).optional }
  it { is_expected.to have_many :rules }

  describe "validations" do
    before :each do
      @valid_promotion = described_class.new name: "A promotion"
    end

    it "valid_promotion is valid" do
      expect(@valid_promotion).to be_valid
    end

    it "validates usage limit" do
      @valid_promotion.usage_limit = -1
      expect(@valid_promotion).not_to be_valid

      @valid_promotion.usage_limit = 100
      expect(@valid_promotion).to be_valid
    end

    it "validates name" do
      @valid_promotion.name = nil
      expect(@valid_promotion).not_to be_valid
    end
  end

  describe ".advertised" do
    let(:promotion) { create(:friendly_promotion) }
    let(:advertised_promotion) { create(:friendly_promotion, advertise: true) }

    it "only shows advertised promotions" do
      advertised = described_class.advertised
      expect(advertised).to include(advertised_promotion)
      expect(advertised).not_to include(promotion)
    end
  end

  describe ".coupons" do
    let(:promotion_code) { create(:friendly_promotion_code) }
    let!(:promotion_with_code) { promotion_code.promotion }
    let!(:another_promotion_code) { create(:friendly_promotion_code, promotion: promotion_with_code) }
    let!(:promotion_without_code) { create(:friendly_promotion) }

    subject { described_class.coupons }

    it "returns only distinct promotions with a code associated" do
      expect(subject).to eq [promotion_with_code]
    end
  end

  describe '.active' do
    subject { described_class.active }

    let(:promotion) { create(:friendly_promotion, starts_at: Date.yesterday, name: "name1") }

    before { promotion }

    it "doesn't return promotion without actions" do
      expect(subject).to be_empty
    end

    context 'when promotion has an action' do
      let(:promotion) { create(:friendly_promotion, :with_adjustable_action, starts_at: Date.yesterday, name: "name1") }

      it 'returns promotion with action' do
        expect(subject).to match [promotion]
      end
    end
  end

  describe '.has_actions' do
    subject { described_class.has_actions }

    let(:promotion) { create(:friendly_promotion, starts_at: Date.yesterday, name: "name1") }

    before { promotion }

    it "doesn't return promotion without actions" do
      expect(subject).to be_empty
    end

    context 'when promotion has two actions' do
      let(:promotion) { create(:friendly_promotion, :with_adjustable_action, starts_at: Date.yesterday, name: "name1") }

      before do
        promotion.actions << SolidusFriendlyPromotions::Actions::AdjustShipment.new(calculator: SolidusFriendlyPromotions::Calculators::Percent.new)
      end

      it 'returns distinct promotion' do
        expect(subject).to match [promotion]
      end
    end
  end

  describe "#apply_automatically" do
    subject { build(:friendly_promotion) }

    it "defaults to false" do
      expect(subject.apply_automatically).to eq(false)
    end

    context "when set to true" do
      before { subject.apply_automatically = true }

      it "should remain valid" do
        expect(subject).to be_valid
      end

      it "invalidates the promotion when it has a path" do
        subject.path = "foo"
        expect(subject).to_not be_valid
        expect(subject.errors).to include(:apply_automatically)
      end
    end
  end

  describe "#usage_limit_exceeded?" do
    subject { promotion.usage_limit_exceeded? }

    shared_examples "it should" do
      context "when there is a usage limit" do
        context "and the limit is not exceeded" do
          let(:usage_limit) { 10 }
          it { is_expected.to be_falsy }
        end
        context "and the limit is exceeded" do
          let(:usage_limit) { 1 }
          context "on a different order" do
            before do
              FactoryBot.create(
                :completed_order_with_friendly_promotion,
                promotion: promotion
              )
              promotion.actions.first.adjustments.update_all(eligible: true)
            end
            it { is_expected.to be_truthy }
          end
          context "on the same order" do
            it { is_expected.to be_falsy }
          end
        end
      end
      context "when there is no usage limit" do
        let(:usage_limit) { nil }
        it { is_expected.to be_falsy }
      end
    end

    context "with an item-level adjustment" do
      let(:promotion) do
        FactoryBot.create(
          :friendly_promotion,
          :with_line_item_adjustment,
          code: "discount",
          usage_limit: usage_limit
        )
      end
      before do
        order.friendly_order_promotions.create(
          promotion_code: promotion.codes.first,
          promotion: promotion
        )
        order.recalculate
      end
      context "when there are multiple line items" do
        let(:order) { FactoryBot.create(:order_with_line_items, line_items_count: 2) }
        describe "the first item" do
          let(:promotable) { order.line_items.first }
          it_behaves_like "it should"
        end
        describe "the second item" do
          let(:promotable) { order.line_items.last }
          it_behaves_like "it should"
        end
      end
      context "when there is a single line item" do
        let(:order) { FactoryBot.create(:order_with_line_items) }
        let(:promotable) { order.line_items.first }
        it_behaves_like "it should"
      end
    end
  end

  describe "#usage_count" do
    let(:promotion) do
      FactoryBot.create(
        :friendly_promotion,
        :with_line_item_adjustment,
        code: "discount"
      )
    end

    subject { promotion.usage_count }

    context "when the code is applied to a non-complete order" do
      let(:order) { FactoryBot.create(:order_with_line_items) }
      before do
        order.friendly_order_promotions.create(
          promotion_code: promotion.codes.first,
          promotion: promotion
        )
        order.recalculate
      end
      it { is_expected.to eq 0 }
    end
    context "when the code is applied to a complete order" do
      let!(:order) do
        FactoryBot.create(
          :completed_order_with_friendly_promotion,
          promotion: promotion
        )
      end
      context "and the promo is eligible" do
        it { is_expected.to eq 1 }
      end
      context "and the promo is ineligible" do
        before { order.all_adjustments.friendly_promotion.update_all(eligible: false) }
        it { is_expected.to eq 0 }
      end
      context "and the order is canceled" do
        before { order.cancel! }
        it { is_expected.to eq 0 }
        it { expect(order.state).to eq 'canceled' }
      end
    end
  end


  context "#inactive" do
    let(:promotion) { create(:friendly_promotion, :with_adjustable_action) }

    it "should not be exipired" do
      expect(promotion).not_to be_inactive
    end

    it "should be inactive if it hasn't started yet" do
      promotion.starts_at = Time.current + 1.day
      expect(promotion).to be_inactive
    end

    it "should be inactive if it has already ended" do
      promotion.expires_at = Time.current - 1.day
      expect(promotion).to be_inactive
    end

    it "should not be inactive if it has started already" do
      promotion.starts_at = Time.current - 1.day
      expect(promotion).not_to be_inactive
    end

    it "should not be inactive if it has not ended yet" do
      promotion.expires_at = Time.current + 1.day
      expect(promotion).not_to be_inactive
    end

    it "should not be inactive if current time is within starts_at and expires_at range" do
      promotion.starts_at = Time.current - 1.day
      promotion.expires_at = Time.current + 1.day
      expect(promotion).not_to be_inactive
    end
  end

  describe '#not_started?' do
    let(:promotion) { SolidusFriendlyPromotions::Promotion.new(starts_at: starts_at) }
    subject { promotion.not_started? }

    context 'no starts_at date' do
      let(:starts_at) { nil }
      it { is_expected.to be_falsey }
    end

    context 'when starts_at date is in the past' do
      let(:starts_at) { Time.current - 1.day }
      it { is_expected.to be_falsey }
    end

    context 'when starts_at date is not already reached' do
      let(:starts_at) { Time.current + 1.day }
      it { is_expected.to be_truthy }
    end
  end

  describe '#started?' do
    let(:promotion) { SolidusFriendlyPromotions::Promotion.new(starts_at: starts_at) }
    subject { promotion.started? }

    context 'when no starts_at date' do
      let(:starts_at) { nil }
      it { is_expected.to be_truthy }
    end

    context 'when starts_at date is in the past' do
      let(:starts_at) { Time.current - 1.day }
      it { is_expected.to be_truthy }
    end

    context 'when starts_at date is not already reached' do
      let(:starts_at) { Time.current + 1.day }
      it { is_expected.to be_falsey }
    end
  end

  describe '#expired?' do
    let(:promotion) { SolidusFriendlyPromotions::Promotion.new(expires_at: expires_at) }
    subject { promotion.expired? }

    context 'when no expires_at date' do
      let(:expires_at) { nil }
      it { is_expected.to be_falsey }
    end

    context 'when expires_at date is not already reached' do
      let(:expires_at) { Time.current + 1.day }
      it { is_expected.to be_falsey }
    end

    context 'when expires_at date is in the past' do
      let(:expires_at) { Time.current - 1.day }
      it { is_expected.to be_truthy }
    end
  end

  describe '#not_expired?' do
    let(:promotion) { SolidusFriendlyPromotions::Promotion.new(expires_at: expires_at) }
    subject { promotion.not_expired? }

    context 'when no expired_at date' do
      let(:expires_at) { nil }
      it { is_expected.to be_truthy }
    end

    context 'when expires_at date is not already reached' do
      let(:expires_at) { Time.current + 1.day }
      it { is_expected.to be_truthy }
    end

    context 'when expires_at date is in the past' do
      let(:expires_at) { Time.current - 1.day }
      it { is_expected.to be_falsey }
    end
  end

  context "#active" do
    it "shouldn't be active if it has started already" do
      promotion.starts_at = Time.current - 1.day
      expect(promotion.active?).to eq(false)
    end

    it "shouldn't be active if it has not ended yet" do
      promotion.expires_at = Time.current + 1.day
      expect(promotion.active?).to eq(false)
    end

    it "shouldn't be active if current time is within starts_at and expires_at range" do
      promotion.starts_at = Time.current - 1.day
      promotion.expires_at = Time.current + 1.day
      expect(promotion.active?).to eq(false)
    end

    it "shouldn't be active if there are no start and end times set" do
      promotion.starts_at = nil
      promotion.expires_at = nil
      expect(promotion.active?).to eq(false)
    end

    context 'when promotion has an action' do
      let(:promotion) { create(:promotion, :with_action, name: "name1") }

      it "should be active if it has started already" do
        promotion.starts_at = Time.current - 1.day
        expect(promotion.active?).to eq(true)
      end

      it "should be active if it has not ended yet" do
        promotion.expires_at = Time.current + 1.day
        expect(promotion.active?).to eq(true)
      end

      it "should be active if current time is within starts_at and expires_at range" do
        promotion.starts_at = Time.current - 1.day
        promotion.expires_at = Time.current + 1.day
        expect(promotion.active?).to eq(true)
      end

      it "should be active if there are no start and end times set" do
        promotion.starts_at = nil
        promotion.expires_at = nil
        expect(promotion.active?).to eq(true)
      end
    end
  end

  context "#products" do
    let(:promotion) { create(:friendly_promotion) }

    context "when it has product rules with products associated" do
      let(:promotion_rule) { SolidusFriendlyPromotions::Rules::Product.new }

      before do
        promotion_rule.promotion = promotion
        promotion_rule.products << create(:product)
        promotion_rule.save
      end

      it "should have products" do
        expect(promotion.reload.products.size).to eq(1)
      end
    end

    context "when there's no product rule associated" do
      it "should not have products but still return an empty array" do
        expect(promotion.products).to be_blank
      end
    end
  end

  # regression for https://github.com/spree/spree/issues/4059
  # admin form posts the code and path as empty string
  describe "normalize blank values for path" do
    it "will save blank value as nil value instead" do
      promotion = Spree::Promotion.create(name: "A promotion", path: "")
      expect(promotion.path).to be_nil
    end
  end

  describe '#used_by?' do
    subject { promotion.used_by? user, [excluded_order] }

    let(:promotion) { create :friendly_promotion, :with_adjustable_action }
    let(:user) { create :user }
    let(:order) { create :order_with_line_items, user: user }
    let(:excluded_order) { create :order_with_line_items, user: user }

    before do
      order.user_id = user.id
      order.save!
    end

    context 'when the user has used this promo' do
      before do
        order.friendly_order_promotions.create(
          promotion: promotion
        )
        order.recalculate
        order.completed_at = Time.current
        order.save!
      end

      context 'when the order is complete' do
        it { is_expected.to be true }

        context 'when the promotion was not eligible' do
          let(:adjustment) { order.all_adjustments.first }

          before do
            adjustment.eligible = false
            adjustment.save!
          end

          it { is_expected.to be false }
        end

        context 'when the only matching order is the excluded order' do
          let(:excluded_order) { order }
          it { is_expected.to be false }
        end
      end

      context 'when the order is not complete' do
        let(:order) { create :order, user: user }

        # The before clause above sets the completed at
        # value for this order
        before { order.update completed_at: nil }

        it { is_expected.to be false }
      end
    end

    context 'when the user has not used this promo' do
      it { is_expected.to be false }
    end
  end
end
