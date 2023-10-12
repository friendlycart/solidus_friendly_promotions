# frozen_string_literal: true

module SolidusFriendlyPromotions
  module Rules
    # A rule to limit a promotion based on products in the order.  Can
    # require all or any of the products to be present.  Valid products
    # either come from assigned product group or are assingned directly to
    # the rule.
    class Product < PromotionRule
      include LineItemApplicableOrderRule

      has_many :products_promotion_rules,
        dependent: :destroy,
        foreign_key: :promotion_rule_id,
        class_name: "SolidusFriendlyPromotions::ProductsPromotionRule"
      has_many :products, class_name: "Spree::Product", through: :products_promotion_rules

      def preload_relations
        [:products]
      end

      MATCH_POLICIES = %w[any all none only].freeze

      validates :preferred_match_policy, inclusion: {in: MATCH_POLICIES}

      preference :match_policy, :string, default: MATCH_POLICIES.first

      # scope/association that is used to test eligibility
      def eligible_products
        products
      end

      def order_eligible?(order)
        return true if eligible_products.empty?

        case preferred_match_policy
        when "all"
          unless eligible_products.all? { |product| order_products(order).include?(product) }
            eligibility_errors.add(:base, eligibility_error_message(:missing_product), error_code: :missing_product)
          end
        when "any"
          unless order_products(order).any? { |product| eligible_products.include?(product) }
            eligibility_errors.add(:base, eligibility_error_message(:no_applicable_products),
              error_code: :no_applicable_products)
          end
        when "none"
          unless order_products(order).none? { |product| eligible_products.include?(product) }
            eligibility_errors.add(:base, eligibility_error_message(:has_excluded_product),
              error_code: :has_excluded_product)
          end
        when "only"
          unless order_products(order).all? { |product| eligible_products.include?(product) }
            eligibility_errors.add(:base, eligibility_error_message(:has_excluded_product),
              error_code: :has_excluded_product)
          end
        else
          raise "unexpected match policy: #{preferred_match_policy.inspect}"
        end

        eligibility_errors.empty?
      end

      def line_item_eligible?(line_item, _options = {})
        # The order level eligibility check happens first, and if none of the products
        # are in the order, then no line items should be available to check.
        raise "This should not happen" if preferred_match_policy == "none"
        product_ids.include?(line_item.variant.product_id)
      end

      def product_ids_string
        product_ids.join(",")
      end

      def product_ids_string=(product_ids)
        self.product_ids = product_ids.to_s.split(",").map(&:strip)
      end

      private

      def order_products(order)
        order.line_items.map(&:variant).map(&:product)
      end
    end
  end
end
