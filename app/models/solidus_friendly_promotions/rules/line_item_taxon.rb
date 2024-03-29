# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    class LineItemTaxon < PromotionRule
      include LineItemLevelRule

      has_many :promotion_rule_taxons, class_name: "SolidusFriendlyPromotions::PromotionRulesTaxon", foreign_key: :promotion_rule_id,
        dependent: :destroy
      has_many :taxons, through: :promotion_rule_taxons, class_name: "Spree::Taxon"

      MATCH_POLICIES = %w[include exclude].freeze

      validates :preferred_match_policy, inclusion: {in: MATCH_POLICIES}

      preference :match_policy, :string, default: MATCH_POLICIES.first

      def eligible?(line_item, _options = {})
        found = Spree::Classification.where(
          product_id: line_item.variant.product_id,
          taxon_id: rule_taxon_ids_with_children
        ).exists?

        case preferred_match_policy
        when "include"
          found
        when "exclude"
          !found
        else
          raise "unexpected match policy: #{preferred_match_policy.inspect}"
        end
      end

      def taxon_ids_string
        taxons.pluck(:id).join(",")
      end

      def taxon_ids_string=(taxon_ids)
        taxon_ids = taxon_ids.to_s.split(",").map(&:strip)
        self.taxons = Spree::Taxon.find(taxon_ids)
      end

      def updateable?
        true
      end

      private

      # ids of taxons rules and taxons rules children
      def rule_taxon_ids_with_children
        taxons.flat_map { |taxon| taxon.self_and_descendants.ids }.uniq
      end
    end
  end
end
