# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    class Taxon < PromotionRule
      include LineItemApplicableOrderRule

      has_many :promotion_rules_taxons, class_name: "SolidusFriendlyPromotions::PromotionRulesTaxon", foreign_key: :promotion_rule_id,
        dependent: :destroy
      has_many :taxons, through: :promotion_rules_taxons, class_name: "Spree::Taxon"

      def preload_relations
        [:taxons]
      end

      MATCH_POLICIES = %w[any all none].freeze

      validates :preferred_match_policy, inclusion: {in: MATCH_POLICIES}

      preference :match_policy, :string, default: MATCH_POLICIES.first

      def order_eligible?(order)
        order_taxons = taxons_in_order(order)

        case preferred_match_policy
        when "all"
          matches_all = taxons.all? do |rule_taxon|
            order_taxons.where(id: rule_taxon.self_and_descendants.ids).exists?
          end

          unless matches_all
            eligibility_errors.add(:base, eligibility_error_message(:missing_taxon), error_code: :missing_taxon)
          end
        when "any"
          unless order_taxons.where(id: rule_taxon_ids_with_children).exists?
            eligibility_errors.add(
              :base,
              eligibility_error_message(:no_matching_taxons),
              error_code: :no_matching_taxons
            )
          end
        when "none"
          if order_taxons.where(id: rule_taxon_ids_with_children).exists?
            eligibility_errors.add(
              :base,
              eligibility_error_message(:has_excluded_taxon),
              error_code: :has_excluded_taxon
            )
          end
        else
          raise "unexpected match policy: #{preferred_match_policy.inspect}"
        end

        eligibility_errors.empty?
      end

      def line_item_eligible?(line_item)
        # The order level eligibility check happens first, and if none of the taxons
        # are in the order, then no line items should be available to check.
        raise "This should not happen" if preferred_match_policy == "none"

        raise "unexpected match policy: #{preferred_match_policy.inspect}" unless preferred_match_policy.in?(MATCH_POLICIES)

        Spree::Classification.where(
          product_id: line_item.variant.product_id,
          taxon_id: rule_taxon_ids_with_children
        ).exists?
      end

      def taxon_ids_string
        taxon_ids.join(",")
      end

      def taxon_ids_string=(taxon_ids)
        self.taxon_ids = taxon_ids.to_s.split(",").map(&:strip)
      end

      def updateable?
        true
      end

      private

      # All taxons in an order
      def taxons_in_order(order)
        Spree::Taxon
          .joins(products: {variants_including_master: :line_items})
          .where(spree_line_items: {order_id: order.id})
          .distinct
      end

      # ids of taxons rules and taxons rules children
      def rule_taxon_ids_with_children
        taxons.flat_map { |taxon| taxon.self_and_descendants.ids }.uniq
      end
    end
  end
end
