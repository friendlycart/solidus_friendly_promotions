# frozen_string_literal: true

module SolidusFriendlyPromotions
  class Promotion < Spree::Base
    belongs_to :category, class_name: "SolidusFriendlyPromotions::PromotionCategory", foreign_key: :promotion_category_id, optional: true
    has_many :rules, class_name: "SolidusFriendlyPromotions::PromotionRule"
    has_many :actions, class_name: "SolidusFriendlyPromotions::PromotionAction"
    has_many :codes, class_name: "SolidusFriendlyPromotions::PromotionCode"
    has_many :code_batches, class_name: "SolidusFriendlyPromotions::PromotionCodeBatch"

    validates :name, presence: true
    validates :path, uniqueness: { allow_blank: true, case_sensitive: true }
    validates :usage_limit, numericality: { greater_than: 0, allow_nil: true }
    validates :per_code_usage_limit, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :description, length: { maximum: 255 }
    validate :apply_automatically_disallowed_with_paths

    scope :active, -> { has_actions.started_and_unexpired }
    scope :advertised, -> { where(advertise: true) }
    scope :coupons, -> { joins(:codes).distinct }
    scope :started_and_unexpired, -> do
      table = arel_table
      time = Time.current

      where(table[:starts_at].eq(nil).or(table[:starts_at].lt(time))).
        where(table[:expires_at].eq(nil).or(table[:expires_at].gt(time)))
    end
    scope :has_actions, -> do
      joins(:actions).distinct
    end

    self.allowed_ransackable_associations = ['codes']
    self.allowed_ransackable_attributes = %w[name path promotion_category_id]
    self.allowed_ransackable_scopes = %i[active]

    # All orders that have been discounted using this promotion
    def discounted_orders
      Spree::Order.
        joins(:all_adjustments).
        where(
          spree_adjustments: {
            source_type: "SolidusFriendlyPromotions::PromotionAction",
            source_id: actions.map(&:id),
            eligible: true
          }
        ).distinct
    end

    # Number of times the code has been used overall
    #
    # @param excluded_orders [Array<Spree::Order>] Orders to exclude from usage count
    # @return [Integer] usage count
    def usage_count(excluded_orders: [])
      discounted_orders.
        complete.
        where.not(id: [excluded_orders.map(&:id)]).
        where.not(spree_orders: { state: :canceled }).
        count
    end

    def used_by?(user, excluded_orders = [])
      discounted_orders.
        complete.
        where.not(id: excluded_orders.map(&:id)).
        where(user: user).
        where.not(spree_orders: { state: :canceled }).
        exists?
    end

    # Whether the promotion has exceeded its usage restrictions.
    #
    # @param excluded_orders [Array<Spree::Order>] Orders to exclude from usage limit
    # @return true or false
    def usage_limit_exceeded?(excluded_orders: [])
      if usage_limit
        usage_count(excluded_orders: excluded_orders) >= usage_limit
      end
    end

    def not_expired?
      !expired?
    end

    def not_started?
      !started?
    end

    def started?
      starts_at.nil? || starts_at < Time.current
    end

    def active?
      started? && not_expired? && actions.present?
    end

    def inactive?
      !active?
    end

    def not_expired?
      !expired?
    end

    def expired?
      expires_at.present? && expires_at < Time.current
    end

    def products
      rules.where(type: "SolidusFriendlyPromotions::Rules::Product").flat_map(&:products).uniq
    end

    private

    def apply_automatically_disallowed_with_paths
      return unless apply_automatically

      errors.add(:apply_automatically, :disallowed_with_path) if path.present?
    end
  end
end
