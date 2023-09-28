# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::PromotionGroup, type: :model do
  it { is_expected.to have_many :promotions }

  describe "validation" do
    subject { described_class.new(name: name) }

    let(:name) { "First" }

    context "when all required attributes are specified" do
      it { is_expected.to be_valid }
    end

    context "when name is missing" do
      let(:name) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when position is missing" do
      let(:position) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when position is an unknown value" do
      let(:position) { "Pronto" }

      it { is_expected.not_to be_valid }
    end
  end
end
