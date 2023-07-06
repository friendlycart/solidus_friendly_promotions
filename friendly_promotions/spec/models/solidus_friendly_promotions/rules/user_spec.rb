# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::Rules::User, type: :model do
  it {  is_expected.to have_many(:users) }
  let(:rule) { described_class.new }

  describe "user_ids=" do
    let(:promotion) { create(:friendly_promotion) }
    let(:user) { create(:user) }
    let(:rule) { promotion.rules.new }

    subject { rule.user_ids = [user.id] }

    it "creates a valid rule with a user" do
      expect(rule).to be_valid
    end
  end

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should not be eligible if users are not provided" do
      expect(rule).not_to be_eligible(order)
    end

    it "should be eligible if users include user placing the order" do
      user = mock_model(Spree::LegacyUser)
      users = [user, mock_model(Spree::LegacyUser)]
      allow(rule).to receive_messages(users: users)
      allow(order).to receive_messages(user: user)

      expect(rule).to be_eligible(order)
    end

    it "should not be eligible if user placing the order is not listed" do
      allow(order).to receive_messages(user: mock_model(Spree::LegacyUser))
      users = [mock_model(Spree::LegacyUser), mock_model(Spree::LegacyUser)]
      allow(rule).to receive_messages(users: users)

      expect(rule).not_to be_eligible(order)
    end

    # Regression test for https://github.com/spree/spree/issues/3885
    it "can assign to user_ids" do
      user1 = Spree::LegacyUser.create!(email: "test1@example.com")
      user2 = Spree::LegacyUser.create!(email: "test2@example.com")
      rule.user_ids = "#{user1.id}, #{user2.id}"
    end
  end
end
