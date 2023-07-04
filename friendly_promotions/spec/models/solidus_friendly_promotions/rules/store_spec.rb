# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::Rules::Store, type: :model do
  it { is_expected.to have_many(:stores) }

  let(:rule) { described_class.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "is eligible if no stores are provided" do
      expect(rule).to be_eligible(order)
    end

    it "is eligible if stores include the order's store" do
      default_store = Spree::Store.new(name: "Default")
      other_store = Spree::Store.new(name: "Other")

      rule.stores = [default_store, other_store]
      order.store = default_store

      expect(rule).to be_eligible(order)
    end

    it "is not eligible if order is placed in a different store" do
      default_store = Spree::Store.new(name: "Default")
      other_store = Spree::Store.new(name: "Other")

      rule.stores = [other_store]
      order.store = default_store

      expect(rule).not_to be_eligible(order)
    end
  end
end
