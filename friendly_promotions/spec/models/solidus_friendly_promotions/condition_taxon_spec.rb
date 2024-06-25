# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolidusFriendlyPromotions::ConditionTaxon do
  it { is_expected.to belong_to(:taxon).optional }
  it { is_expected.to belong_to(:condition).optional }
end
