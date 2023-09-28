# frozen_string_literal: true

module SolidusFriendlyPromotions
  class PromotionGroup < Spree::Base
    GROUP_PRIORITY_NAMES = %w[Pre Default Post].freeze

    has_many :promotions

    validates :name, presence: true
    validates :position, presence: true, numericality: true
  end
end
