# frozen_string_literal: true

module SolidusFriendlyPromotions
  class FriendlyPromotionAdjuster
    class LoadPromotions
      def initialize(order:, dry_run_promotion: nil)
        @order = order
        @dry_run_promotion = dry_run_promotion
      end

      def call
        promos = connected_order_promotions | sale_promotions
        promos << dry_run_promotion if dry_run_promotion
        promos.flat_map(&:benefits).group_by(&:preload_relations).each do |preload_relations, benefits|
          preload(records: benefits, associations: preload_relations)
          benefits.flat_map(&:conditions).group_by(&:preload_relations).each do |preload_relations, conditions|
            preload(records: conditions, associations: preload_relations)
          end
        end
        promos.reject { |promotion| promotion.usage_limit_exceeded?(excluded_orders: [order]) }
      end

      private

      attr_reader :order, :dry_run_promotion

      def preload(records:, associations:)
        ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
      end

      def connected_order_promotions
        eligible_connected_promotion_ids = order.friendly_order_promotions.select do |order_promotion|
          order_promotion.promotion_code.nil? || !order_promotion.promotion_code.usage_limit_exceeded?(excluded_orders: [order])
        end.map(&:promotion_id)
        order.friendly_promotions.active(reference_time).where(id: eligible_connected_promotion_ids).includes(promotion_includes)
      end

      def sale_promotions
        SolidusFriendlyPromotions::Promotion.where(apply_automatically: true).active(reference_time).includes(promotion_includes)
      end

      def reference_time
        order.completed_at || Time.current
      end

      def promotion_includes
        {
          benefits: :conditions
        }
      end
    end
  end
end
