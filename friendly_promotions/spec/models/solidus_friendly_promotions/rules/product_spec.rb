# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::Rules::Product, type: :model do
  let(:rule_options) { {} }
  let(:rule) { described_class.new(rule_options) }

  it { is_expected.to have_many(:products) }

  describe "#eligible?(order)" do
    let(:order) { Spree::Order.new }
    let(:product_one) { build(:product) }
    let(:product_two) { build(:product) }
    let(:product_three) { build(:product) }

    it "is eligible if there are no products" do
      allow(rule).to receive_messages(eligible_products: [])
      expect(rule).to be_eligible(order)
    end

    context "with 'any' match policy" do
      let(:rule_options) { super().merge(preferred_match_policy: "any") }

      it "is eligible if any of the products is in eligible products" do
        allow(rule).to receive_messages(order_products: [product_one, product_two])
        allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        expect(rule).to be_eligible(order)
      end

      context "when none of the products are eligible products" do
        before do
          allow(rule).to receive_messages(order_products: [product_one])
          allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        end

        it { expect(rule).not_to be_eligible(order) }

        it "sets an error message" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.full_messages.first)
            .to eq "You need to add an applicable product before applying this coupon code."
        end

        it "sets an error code" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.details[:base].first[:error_code])
            .to eq :no_applicable_products
        end
      end
    end

    context "with 'all' match policy" do
      let(:rule_options) { super().merge(preferred_match_policy: "all") }

      it "is eligible if all of the eligible products are ordered" do
        allow(rule).to receive_messages(order_products: [product_three, product_two, product_one])
        allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        expect(rule).to be_eligible(order)
      end

      context "when any of the eligible products is not ordered" do
        before do
          allow(rule).to receive_messages(order_products: [product_one, product_two])
          allow(rule).to receive_messages(eligible_products: [product_one, product_two, product_three])
        end

        it { expect(rule).not_to be_eligible(order) }

        it "sets an error message" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.full_messages.first).to eq(
            "This coupon code can't be applied because you don't have all of the necessary products in your cart."
          )
        end

        it "sets an error code" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.details[:base].first[:error_code])
            .to eq :missing_product
        end
      end
    end

    context "with 'none' match policy" do
      let(:rule_options) { super().merge(preferred_match_policy: "none") }

      it "is eligible if none of the order's products are in eligible products" do
        allow(rule).to receive_messages(order_products: [product_one])
        allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        expect(rule).to be_eligible(order)
      end

      context "when any of the order's products are in eligible products" do
        before do
          allow(rule).to receive_messages(order_products: [product_one, product_two])
          allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        end

        it { expect(rule).not_to be_eligible(order) }

        it "sets an error message" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.full_messages.first)
            .to eq "Your cart contains a product that prevents this coupon code from being applied."
        end

        it "sets an error code" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.details[:base].first[:error_code])
            .to eq :has_excluded_product
        end
      end
    end

    context "with 'only' match policy" do
      let(:rule_options) { super().merge(preferred_match_policy: "only") }

      it "is not eligible if none of the order's products are in eligible products" do
        allow(rule).to receive_messages(order_products: [product_one])
        allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        expect(rule).not_to be_eligible(order)
      end

      it "is eligible if all of the order's products are in eligible products" do
        allow(rule).to receive_messages(order_products: [product_one])
        allow(rule).to receive_messages(eligible_products: [product_one])
        expect(rule).to be_eligible(order)
      end

      context "when any of the order's products are in eligible products" do
        before do
          allow(rule).to receive_messages(order_products: [product_one, product_two])
          allow(rule).to receive_messages(eligible_products: [product_two, product_three])
        end

        it { expect(rule).not_to be_eligible(order) }

        it "sets an error message" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.full_messages.first)
            .to eq "Your cart contains a product that prevents this coupon code from being applied."
        end

        it "sets an error code" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.details[:base].first[:error_code])
            .to eq :has_excluded_product
        end
      end
    end

    context "with an invalid match policy" do
      let(:rule) do
        described_class.create!(
          promotion: create(:friendly_promotion),
          products_promotion_rules: [
            SolidusFriendlyPromotions::ProductsPromotionRule.new(product: product)
          ]
        ).tap do |rule|
          rule.preferred_match_policy = "invalid"
          rule.save!(validate: false)
        end
      end
      let(:product) { order.line_items.first!.product }
      let(:order) { create(:order_with_line_items, line_items_count: 1) }

      it "raises" do
        expect {
          rule.eligible?(order)
        }.to raise_error('unexpected match policy: "invalid"')
      end
    end
  end
end
